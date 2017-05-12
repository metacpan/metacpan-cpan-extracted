package SVN::Notify::Snapshot;
$SVN::Notify::Snapshot::VERSION = '0.04';

use strict;
use File::Spec;
use File::Path qw( mkpath );
use File::Temp qw( tempdir );
use File::Basename qw( dirname fileparse );
use SVN::Notify ();
@SVN::Notify::Snapshot::ISA = qw(SVN::Notify);

use constant SuffixMap => {
    '.tar'      => '_tar',
    '.tar.gz'   => '_tar_gzip',
    '.tgz'      => '_tar_gzip',
    '.tbz'      => '_tar_bzip2',
    '.tbz2'     => '_tar_bzip2',
    '.tar.bz2'  => '_tar_bzip2',
    '.zip'      => '_zip',
};

__PACKAGE__->register_attributes(
    handle_path => 'handle-path=s',
    append_rev  => 'append-rev',
    tag_regex	=> 'tag-regex=s',
);

sub prepare {
    my $self = shift;
    $self->prepare_recipients;
    $self->prepare_files;
}

sub execute {
    my ($self) = @_;
    my $repos = $self->{repos_path} or return;
    my $path = $self->{handle_path} or die "Must specify handle_path";
    $DB::single = 1;
    foreach my $to ( @{$self->{to}} ) {
	my $temp = tempdir( CLEANUP => 0 );

	my ($to_base, $to_path, $to_suffix) = fileparse($to, qr{\..*});
	my $method = $self->SuffixMap->{lc($to_suffix)}
	    or die "Unknown suffix: $to_suffix";

	my $base = (
	    defined($self->{snapshot_base})
		? $self->{snapshot_base} : $to_base
	);

	if ( $self->append_rev ) {
	    $to = "$to_path/$to_base-".$self->{revision}.$to_suffix;
	    $base .= '-'.$self->{revision};
	}

	if ( defined $self->{tag_regex} ) {
	    my $regex = $self->{tag_regex};
            my ($tag) = grep /$regex/, @{$self->{'files'}->{'A'}};
	    return unless $tag;
	    $path = $tag;
	    unless ( $self->append_rev ) {
		$tag =~ s/^.+\/tags\/(.+)/$1/;
		$base = $tag;
	    }
	}

	my $from = File::Spec->catdir($temp, $base);
	mkpath([ dirname($from) ]) unless -d dirname($from);

	$self->_run(
	    'svn', 'export',
	    -r => $self->{revision},
	    "file://$repos/$path" => $from,
	);

	$self->can($method)->($self, $temp, $from, $to);
    }
}

sub _tar {
    my ($self, $temp, $from, $to, $mode) = @_;
    my $TAR = SVN::Notify->find_exe('tar') || '/bin/tar';

    $mode ||= '-cf';
    $self->_run( $TAR, $mode, $to, '-C' => $temp, '.' ) ;
}

sub _tar_gzip {
    my $self = shift;
    $self->_tar(@_, '-czf');
}

sub _tar_bzip2 {
    my $self = shift;
    $self->_tar(@_, '-cjf');
}

sub _zip {
    my ($self, $temp, $from, $to, $mode) = @_;
    my $ZIP = SVN::Notify->find_exe('zip');

    require Cwd;
    my $dir = Cwd::getcwd();
    chdir $temp;

    $self->_run( $ZIP, -r => $to, '.' );
}

sub _run {
    my $self = shift;
    (system { $_[0] } @_) == 0 or die "Running [@_] failed with $?: $!";
}

1;

__END__

=head1 NAME

SVN::Notify::Snapshot - Take snapshots from Subversion activity

=head1 VERSION

This document describes version 0.04 of SVN::Notify::Snapshot,
released June 28, 2008.

=head1 SYNOPSIS

Use F<svnnotify> in F<post-commit>:

  svnnotify --repos-path "$1" --revision "$2" \
    --to "/tmp/snapshot-$2.tar.gz" --handler Snapshot \
    [--append-rev] --handle-path pathname [options]
    [--tag-regex]

or as part of a SVN::Notify::Config YAML file:

  #!/usr/bin/perl -MSVN::Notify::Config=$0
  --- #YAML:1.0
  '':
    PATH: "/usr/local/bin:/usr/bin"
  '/project1/trunk':
    handler: Snapshot
    append-rev: 1
    to: "/srv/www/htdocs/snapshot.tgz"

Produce snapshots of a repository path.  Typically used as part of a
postcommit script, which will automatically e.g. a trunk-latest.tar.gz
file for every commit to a specified path.

=head1 USAGE

As a subclass of L<SVN::Notify>, there are several ways to integrate this
module into your postcommit script:

=over 4

=item 1. postcommit script

Add a line to an existing postcommit script that sets the C<--handler>
commandline option to "Snapshot".  This method has the drawback that it
will require multiple Perl interpreters to start up (one per handler
line), which B<will> delay the commit from completing on the client.
Unless you use C<--to-regex-map>, it will also mean that each line will be
called for each revision committed, even if the path of interest hasn't
changed.

=item 2. SVN::Notify::Config stanza

Multiple handlers can be configured in a single L<SVN::Notify::Config>
YAML file, which acts both as the configuration data as well as the
postcommit script itself.  This method also ensures that the Snapshot
handler will only be called when a change is made to the associated path
(like C<--to-regex-map> in the commandline case).

=back

=head2 Options

In addition to all of the options available to the base L<SVN::Notify>
class, there are several that are specific to the Snapshot handler.

=over 4

=item * handle-path

This commandline argument specifies the portion of the repository to take
snapshot from, is not optional.  It will be automatically set when using
either C<--to-regex-map> or when executed within a L<SVN::Notify::Config>
script, however.

=item * snapshot-base

By default, the base path inside the snapshot will be the basename of
the C<--to> argument, but you may override it with C<--snapshot-base>.
For example, if you are taking a snapshot of C<project1/trunk>, you may
want to set the snapshot-base to "project1" instead.

=item * append-rev

If you are passing both the C<--revision> and C<--to> arguments to
svnnotify on the commandline, you can always construct the filename to
include the revision by using shell substitution variables (like the
example in the L<SYNOPSIS>.  However, if you are using a YAML config file
or the C<--to-regex-map> commandline option, you may want to use the
C<append-rev> option, which will insert a hyphen and the revision into the
destination filename between the basename and the suffix.

For example, in the L<SYNOPSIS> above, the YAML stanza will generate files
like:

  /srv/www/htdocs/snapshot-1.tgz
  /srv/www/htdocs/snapshot-5.tgz
  /srv/www/htdocs/snapshot-6.tgz

assuming that the C</project1/trunk> changed in revs 1, 5, and 6.

=back

=head1 AUTHORS

John Peacock E<lt>jpeacock@cpan.orgE<gt>

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>


=head1 SEE ALSO

L<SVN::Notify>, L<SVN::Notify::Config>

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-svn-notify-snapshot@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2008 John Peacock E<lt>jpeacock@cpan.orgE<gt>.

Portions copyright 2004 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
