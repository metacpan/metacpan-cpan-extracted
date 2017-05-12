# -*- cperl-indent-level: 4 -*- vi:nowrap:
package Perl::Repository::APC2SVN;

use strict;
use warnings;
use File::Basename qw(dirname);

my $Id = q$Id: APC2SVN.pm 220 2006-10-22 10:51:44Z k $;
our $VERSION = sprintf "%.3f", 1 + substr(q$Rev: 220 $,4)/1000;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(latest_change url_latest_change get_dirs_to_add
get_dirs_to_delete delete_empty_dirs);
our $DEBUG = 0; # apologies for the inconvenient debugging switch

sub latest_change ();
sub url_latest_change ($);
sub get_dirs_to_add (@);
sub get_dirs_to_delete (@);
sub dir_will_be_empty ($);
sub delete_empty_dirs (@);


# to request the whole log is very slow for large repositories (4 secs
# for 10000 revisions), much slower than repeatedly requesting dozens
# of single log entries, but still faster than 1000s of single log
# requests. So we make a compromise: if requesting single log entries
# leads to a quick success, all is good, but after 4 tries we request
# the whole log
sub latest_change () {
    my $lastpatch = 0;
    my($rev);
    warn "DEBUG: Running svn info -R" if $DEBUG;
    open my $svninfo, "svn info -R |" or die "Can't fork 'svn info': $!\n";
    local $/;
    local $_ = <$svninfo>;
    close $svninfo;
    use List::Util qw(max);
    $rev = max(/^Last Changed Rev: (\d+)/gm);
    $/ = "\n";
    my $triesleft = 4; # maximum
    until ($lastpatch) {
        # warn "Trying rev $rev";
        last unless $rev;
        warn "DEBUG: Running svn log -r $rev" if $DEBUG;
        open my $svnlog, "svn log -r $rev |" or die "Can't fork 'svn log': $!\n";
        while (<$svnlog>) {
            chomp;
            if ($. == 2) {
                if (/^rev (\d+):/) {
                    $rev = $1;
                } else {
                    die "Unexpected log-status-line: '$_'";
                }
            } elsif (/^Change (\d+) by /) {
                $lastpatch = $1;
                last;
            }
        }
        1 while <$svnlog>; # bug in svn? it returns false if we break the pipe???
        unless (close $svnlog) {
          warn "Warning (probably harmless): Can't close 'svn log -r $rev': $!";
        }
        $rev-- unless $lastpatch;
        last unless $rev;
        last unless --$triesleft > 0;
    }
    return $lastpatch if $lastpatch;
    # our speedup strategy didn't work out, so let's do the safe thing
    warn "DEBUG: Running svn log" if $DEBUG;
    open my $svnlog, 'svn log |'
        or die "Can't fork 'svn log': $!\n";
    while (<$svnlog>) {
        if (/^Change (\d+) by /) {
            $lastpatch = $1;
            last;
        }
    }
    close $svnlog;
    $lastpatch;
}

# If we don't have a repository checked out, we cannot use the trick
# with 'svn info' as in latest_change(), so we ask directly the
# repository for the whole log
sub url_latest_change ($) {
  my $url = shift;
  my $lastpatch = 0;
  warn "DEBUG: Running svn log $url" if $DEBUG;
  open my $svnlog, "svn log $url |"
      or die "Can't fork 'svn log $url': $!\n";
  local($/) = "\n";
  while (<$svnlog>) {
    if (/^Change (\d+) by /) {
      $lastpatch = $1;
      last;
    }
  }
  close $svnlog;
  $lastpatch;
}

# Returns all directories to add to the repository
# for a given set of added files
sub get_dirs_to_add (@) {
    return () if @_ == 0;
    my %dirs = ();
    for my $file (@_) {
        my $dir = $file;
        while (($dir = dirname $dir) ne ".") {
            $dirs{$dir} = 1 unless $dirs{$dir} or -d $dir;
        }
    }
    # Order is important
    return sort { length $a <=> length $b } keys %dirs;
}

# get_dirs_to_delete returns all additional directories to delete from
# the repository for a given set of files or directories that have
# already been scheduled for deletion.
# (After some experiments with the behaviour of svn, I decided that the
# safest way was to use the output of qx(svn info $dir/*) on each $dir
# parent of a deleted file, and to check that every file under version
# control in it is scheduled for deletion. This is not the fastest way
# but it's less error-prone that every other method I can think
# of right now.)

sub get_dirs_to_delete (@) {
    return () if @_ == 0;
    my %dirs = ();
    for my $file (@_) {
	my $dir = dirname $file;
        $dirs{$dir} = 1 if ! $dirs{$dir} and dir_will_be_empty($dir);
	# NOT equiv: $dirs{$dir} ||= dir_will_be_empty($dir);
    }
    return sort { length $b <=> length $a } keys %dirs;
}

sub dir_will_be_empty ($) {
    my $dir = shift;
    my $ret = 1;
    my $count = 0;
    my @glob = grep !/\/\.svn$/, glob "$dir/*";
    return 1 unless @glob;
    my $glob = join " ", map { "'$_'" } @glob;
    warn "DEBUG: Running svn info $glob" if $DEBUG;
    open my $svninfo, "svn info $glob |"
	or die "Can't fork 'svn info': $!\n";
    while (<$svninfo>) {
	next if !/^Schedule: (\w+)/;
	++$count;
	$ret = 0 if $1 ne 'delete';
    }
    close $svninfo;
    return $count ? $ret : 0;
}

sub delete_empty_dirs (@) {
    my @files = @_;
    my @to_delete_recursively = my @to_delete = get_dirs_to_delete(@files);
    if (@to_delete) {
        warn "DEBUG: Running svn rm on to_delete[@to_delete]" if $DEBUG;
	system(svn => 'rm', @to_delete)
	    and die "Error executing svn rm : $!,$?\n";
	push @to_delete_recursively, delete_empty_dirs(@to_delete);
    }
    @to_delete_recursively;
}



1;

__END__

=head1 NAME

Perl::Repository::APC2SVN - Utility functions for APC and Subversion

=head1 SYNOPSIS

  use Perl::Repository::APC2SVN;

=head1 DESCRIPTION

The functions in this module are used by both perlpatch2svn and
apc2svn. They are not of much use outside of the two scripts. Please
RTFS if you're interested.

=head1 AUTHOR

Rafael Garcia Suarez and Andreas Koenig

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=head1 SEE ALSO

perlpatch2svn, apc2svn

=cut
