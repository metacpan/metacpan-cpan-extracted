package SVN::SVNLook;
use strict;
use warnings;
use Carp qw(cluck);

our $VERSION = 0.04;

=head1 NAME

SVN::SVNLook - Perl wrapper to the svnlook command.

=head1 SYNOPSIS

  use SVN::SVNLook;

  my $revision = 1;
  my $svnlook = SVN::SVNLook->new(repo => 'repo url',
                                   cmd => 'path to svn look');
  my ($author,$date,$logmessage) = $svnlook->info(revision => $revision);

  print "Author $author\n";
  print "Date $date\n";
  print "LogMessage $logmessage\n";

=head1 DESCRIPTION

SVN::SVNLook runs the command line client. This module was created to
make adding hooks script easier to manipulate.

=cut

=head1 METHODs

=head2 youngest

  youngest ();

Perform the youngest command on the repository.
Returns the revision number of the most recent revision as a scalar.

=head2 info

  info (revision=>$revision);

Perform the info command, for a given revision or transaction using
named parameters, or a single parameter will be assumed to mean
revision for backwards compatibility. The information returned is an
array containing author, date, and log message. If no $revision is
specified, info for the youngest revision is returned.

=head2 author

  author (revision=>$revision);

Perform the author command, for a given revision or transaction using
named parameters or a single parameter will be assumed to mean
revision for backwards compatibility. The information returned is the
author message. If no $revision or transaction is specified, author
for the youngest revision is returned.

=head2 dirschanged

  dirschanged (revision=>$revision)

Performs the dirs-changed command, for a given revision or transaction
using named parameters, or a single parameter will be assumed to mean
revision for backwards compatibility. This method returns a boolean and
an array reference.

=head2 fileschanged

  fileschanged (revision=>$revision)

Performs the changed command, for a given revision or transaction
using named parameters or a single parameter will be assumed to mean
revision for backwards compatibility this method returns 3 array
references added, deleted and modified.

=head2 diff

  diff (revision=>$revision)

Performs the diff command, for a given revision or transaction using
named parameters or a single parameter will be assumed to mean
revision for backwards compatability this method returns a hash
reference, with each file being the key and value being the diff info.

=cut


sub new {
    my $self = {}; 
    my $class = shift;
    %$self = @_;
    $self->{repo} ||= $self->{target};
    die "no repository specified" unless $self->{repo};
    return bless $self, $class;
}

sub youngest
{
    my $self = shift;
    my ($rev) = _read_from_process($self->{cmd}, 'youngest', $self->{repo});
    return $rev;
}
sub info
{
    my $self = shift;
	my %args;
    if ($#_ == 0)
    {
		$args{revision} = shift;
    }
    else
    {
		%args = @_;
    }
    my @svnlooklines = _read_from_process(
        $self->{cmd},
        'info',
        $self->{repo},
        ($args{revision} ? ('-r', $args{revision}) : ()),
        ($args{transaction} ? ('-t', $args{transaction}) : ()),
    );
    my $author = shift @svnlooklines; # author of this change
    my $date = shift @svnlooklines; # date of change
    shift @svnlooklines; # log message size
    my @log = map { "$_\n" } @svnlooklines;
    my $logmessage = join('',@log);
    return ($author,$date,$logmessage);
}
sub author
{
    my $self = shift;
	my %args;
    if ($#_ == 0)
    {
		$args{revision} = shift;
    }
    else
    {
		%args = @_;
    }
    my @svnlooklines = _read_from_process(
        $self->{cmd},
        'author',
        $self->{repo},
        ($args{revision} ? ('-r', $args{revision}) : ()),
        ($args{transaction} ? ('-t', $args{transaction}) : ()),
    );
    return $svnlooklines[0]; # author of this change
}

sub dirschanged
{
    my $self = shift;
	my %args;
    if ($#_ == 0)
    {
		$args{revision} = shift;
    }
    else
    {
		%args = @_;
    }
    # Figure out what directories have changed using svnlook.
    my @dirschanged = _read_from_process(
        $self->{cmd},
        'dirs-changed',
        $self->{repo},
        ($args{revision} ? ('-r', $args{revision}) : ()),
        ($args{transaction} ? ('-t', $args{transaction}) : ()),
    );	
    my $rootchanged = 0;
    for (my $i=0; $i<@dirschanged; ++$i)
    {
        if ($dirschanged[$i] eq '/')
        {
            $rootchanged = 1;
        }
        else
        {
            $dirschanged[$i] =~ s#^(.+)[/\\]$#$1#;
        }
    }
    return ($rootchanged,\@dirschanged);
}


sub fileschanged
{
    my $self = shift;
	my %args;
    if ($#_ == 0)
    {
		$args{revision} = shift;
    }
    else
    {
		%args = @_;
    }

    # Figure out what files have changed using svnlook.
    my @svnlooklines = _read_from_process(
        $self->{cmd},
        'changed',
        $self->{repo},
        ($args{revision} ? ('-r', $args{revision}) : ()),
        ($args{transaction} ? ('-t', $args{transaction}) : ()),
    );
    # Parse the changed nodes.
    my @adds;
    my @dels;
    my @mods;
    foreach my $line (@svnlooklines)
    {
        my $path = '';
        my $code = '';

        # Split the line up into the modification code and path, ignoring
        # property modifications.
        if ($line =~ /^(.).  (.*)$/)
        {
            $code = $1;
            $path = $2;
        }
        if ($code eq 'A')
        {
            push(@adds, $path);
        }
        elsif ($code eq 'D')
        {
            push(@dels, $path);
        }
        else
        {
            push(@mods, $path);
        }
    }
    return (\@adds,\@dels,\@mods);
}

sub diff
{
    my $self = shift;
	my %args;
    if ($#_ == 0)
    {
		$args{revision} = shift;
    }
    else
    {
		%args = @_;
    }

	my @difflines = _read_from_process(
        $self->{cmd},
        'diff',
        $self->{repo},
        ($args{revision} ? ('-r', $args{revision}) : ()),
        ($args{transaction} ? ('-t', $args{transaction}) : ()),
        ('--no-diff-deleted')
    );
	# Ok we need to split this out now , by file
    my @lin = split(/Modified: (.*)\n=*\n/,join("\n",@difflines));
    shift(@lin);
    my %lines = @lin;
    return %lines;
}
#
# PRIVATE METHODS
# Methods taken from commit-email.pl Copyright subversion team
#

# NB. croak is not a defined subroutine - where did this come from?
# croak is defined in Carp, somehow didnt get included in CPAN post

sub _read_from_process
{
    unless (@_)
    {
        cluck("$0: read_from_process passed no arguments.\n");
    }
    my ($status, @output) = _safe_read_from_pipe(@_);
    if ($status)
    {
        cluck("$0: `@_' failed with this output:", @output);
    }
    else
    {
      return @output;
    }
}
sub _safe_read_from_pipe
{
    unless (@_)
    {
        croak("$0: safe_read_from_pipe passed no arguments.\n");
    }

    my $pid = open(SAFE_READ, '-|');
    unless (defined $pid)
    {
        die "$0: cannot fork: $!\n";
    }
    unless ($pid)
    {
        open(STDERR, ">&STDOUT") or die "$0: cannot dup STDOUT: $!\n";
        exec(@_)or die "$0: cannot exec `@_': $!\n";
    }
    my @output;
    while (<SAFE_READ>)
    {
        s/[\r\n]+$//;
        push(@output, $_);
    }
    close(SAFE_READ);
    my $result = $?;
    my $exit   = $result >> 8;
    my $signal = $result & 127;
    my $cd     = $result & 128 ? "with core dump" : "";
    if ($signal or $cd)
    {
        warn "$0: pipe from `@_' failed $cd: exit=$exit signal=$signal\n";
    }
    if (wantarray)
    {
        return ($result, @output);
    }
    else
    {
        return $result;
    }
}
1;

__END__

=head1 AUTHOR

Salvatore E ScottoDiLuzio, <sal.scotto@gmail.com>
Contributions by Kevin Semande

=head1 COPYRIGHT

Copyright 2005 Salvatore E. ScottoDiLuzio.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
