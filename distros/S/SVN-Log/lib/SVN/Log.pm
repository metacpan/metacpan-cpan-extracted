package SVN::Log;

# $Id: Log.pm 729 2006-01-11 08:20:09Z nik $

use strict;
use warnings;

our $VERSION = 0.03;

=head1 NAME

SVN::Log - Extract change logs from a Subversion server.

=head1 SYNOPSIS

  use SVN::Log;

  my $revs = SVN::Log::retrieve ("svn://host/repos", 1);

  print Dumper ($revs);

=head1 DESCRIPTION

SVN::Log retrieves and parses the commit logs from Subversion repositories.

=head1 VARIABLES

=head2 $FORCE_COMMAND_LINE_SVN

If this is true SVN::Log will use the command line svn client instead of
the subversion perl bindings when it needs to access the repository.

=cut

our $FORCE_COMMAND_LINE_SVN = 0;

=head1 FUNCTIONS

=head2 retrieve

  retrieve('svn://host/repos', $start_rev, $end_rev);

Retrieve one or more log messages from a repository. If a second revision
is not specified, the revision passed will be retrieved, otherwise the range
of revisions from $start_rev to $end_rev will be retrieved.

One or both of $start_rev and $end_rev may be given as C<HEAD>, meaning
the most recent (youngest) revision in the repository.  To retrieve all
the log messages in the repository.

  retrieve('svn://host/repos', 1, 'HEAD');

To do the same thing, but retrieve the log messages in reverse order (i.e.,
most recent log message first):

  retrieve('svn://host/repos, 'HEAD', 1);

The revisions are returned as a reference to an array of hashes.  Each hash
contains the following keys:

=over

=item revision

The number of the revision.

=item paths

A hashref indicating the paths modified by this revision.  Each key is the
name of the path modified in this revision.  The value is a reference to
another hash, with the following possible keys.

=over

=item action

The activity that happened to this path.  One of C<A>, C<M>, or C<D>, for
C<Added>, C<Modified>, or C<Deleted> respectively.  This key is always
present.

=item copyfrom_path

If the action was C<A> or C<M> then this path may have been copied from
another path in the repository.  If it was then this key contains the path
in the repository that the file was originally copied from.

=item copyfrom_rev

If C<copyfrom_path> is set then this value contains the revision that the
path in C<copyfrom_path> was copied from.

=back

=item author

The author of the revision.  May legitimately be undefined if the
repository allows unauthenticated commits (e.g., over WebDAV).

=item date

The date of this revision.

=item message

The commit message from this revision.

=back

Alternatively, you can pass C<retrieve()> a hash containing the repository,
start and end revisions, and a callback function which will be called for
each revision, like this:

  retrieve ({ repository => "svn://svn.example.org/repos",
              start => 1,
              end => 2,
              callback => sub { print @_; } });

The callback will be passed a reference to a hash of paths modified, the
revision, the author, the date, and the message associated with the revision.

See L<SVN::Log::Index> for the cannonical example of how to do this.

=cut

sub retrieve {
  my ($repos, $start_rev, $end_rev, $callback);

  if (scalar @_ == 1 and ref $_[0] eq 'HASH') {
    $repos = $_[0]->{repository};

    $start_rev = $_[0]->{start};

    $start_rev = $_[0]->{revision} unless defined $start_rev;

    $end_rev = $_[0]->{end};

    $callback = $_[0]->{callback};
  } else {
    ($repos, $start_rev, $end_rev) = @_;
  }

  die "need at least a repository and a revision"
    unless defined $repos and defined $start_rev;

  my $revs = [];

  $callback = sub { _handle_log ($revs, @_); } unless defined $callback;

  $end_rev = $start_rev unless defined $end_rev;

  unless ($repos =~ m/^(http|https|svn|file|svn\+ssh):\/\//) {
    $repos = "file://$repos";
  }

  _do_log ($repos, $start_rev, $end_rev, $callback);

  return $revs;
}

sub _do_log {
  # we only pull this in here so that the search portions of this module
  # can be used in environments where the svn libs can't be linked against.
  #
  # this can happen, for example, when apache and mod_perl2 are linked
  # against different versions of the APR libraries than subversion is.
  #
  # not that i happen to have a system like that or anything...
  unless ($FORCE_COMMAND_LINE_SVN) {
    eval {
      require SVN::Core;
      require SVN::Ra;
    };
  }

  if ($@ || $FORCE_COMMAND_LINE_SVN) {
    # oops, we don't have the SVN perl libs installed, so instead we need
    # to fall back to using the command line client the old fashioned way
    goto &_do_log_commandline;
  } else {
    goto &_do_log_bindings;
  }
}

sub _do_log_bindings {
  my ($repos, $start_rev, $end_rev, $callback) = @_;

  my $r = SVN::Ra->new (url => $repos) or die "error opening RA layer: $!";

  if($start_rev eq 'HEAD') {
    $start_rev = $r->get_latest_revnum();
  }

  if($end_rev eq 'HEAD') {
    $end_rev = $r->get_latest_revnum();
  }

  $r->get_log (['/'], $start_rev, $end_rev, 0, 1, 0,
               sub { _handle_log_bindings($callback, @_); });
}

sub _do_log_commandline {
  my ($repos, $start_rev, $end_rev, $callback) = @_;

  open my $log, "svn log -v -r $start_rev:$end_rev $repos|"
    or die "couldn't open pipe to svn process: $!";

  my ($paths, $rev, $author, $date, $msg);

  my $state = 'start';

  my $seprule  = qr/^-{72}$/;
  my $headrule = qr/r(\d+) \| (\w+) \| (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/;

  # XXX i'm sure this can be made much much cleaner...
  while (<$log>) {
    if ($state eq 'start' or $state eq 'message' and m/$seprule/) {
      if ($state eq 'start') {
        $state = 'head';
      } elsif ($state eq 'message') {
        $state = 'head';
        $callback->($paths, $rev, $author, $date, $msg);
      }
    } elsif ($state eq 'head' and m/$headrule/) {
      $rev = $1;
      $author = $2;
      $date = $3;
      $paths = {};
      $msg = "";

      $state = 'paths';
    } elsif ($state eq 'paths') {
      unless (m/^Changed paths:$/) {
        if (m/^$/) {
          $state = 'message';
        } else {
          if (m/^\s+(\w+) (.+)$/) {
	    my $action = $1;
	    my $str    = $2;

	    # If a copyfrom_{path,rev} is listed then include it,
	    # otherwise just note the path and the action.
	    if($str =~ /^(.*?) \(from (.*?):(\d+)\)$/) {
	      $paths->{$1}{action} = $action;
	      $paths->{$1}{copyfrom_path} = $2;
	      $paths->{$1}{copyfrom_rev} = $3;
	    } else {
	      $paths->{$str}{action} = $action;
	    }
          }
        }
      }
    } elsif ($state eq 'message') {
      $msg .= $_;
    }
  }
}

my @fields = qw(paths revision author date message);

# Unpack the svn_log_changed_path_t parameters.  _do_log_command_line()
# can call the user-supplied callback directly.  _do_log_bindings() can't,
# because the list of changed paths (and what was changed) are implemented
# as objects when using the bindings.
#
# This sub calls the relevant methods on the log_changed_path object, and
# replaces the object reference with the methods' return values.  Then it
# calls the user supplied callback.
#
# This way the user callbacks don't need to know whether we're using the
# bindings or the command line client.
sub _handle_log_bindings {
  my $callback = shift;
  my %revision;

  @revision{@fields} = @_;

  if(exists $revision{paths}) {
    foreach my $path (keys %{$revision{paths}}) {
      my $lcp = $revision{paths}{$path};

      delete $revision{paths}{$path};

      $revision{paths}{$path}{action} = $lcp->action();
      if(defined $lcp->copyfrom_path()) {
	$revision{paths}{$path}{copyfrom_path} = $lcp->copyfrom_path();
	$revision{paths}{$path}{copyfrom_rev} = $lcp->copyfrom_rev();
      }
    }
  }

  $callback->(@revision{@fields});
}

sub _handle_log {
  my $revs = shift;
  my %revision;

  @revision{@fields} = @_;
  push @$revs, \%revision;
}

1;
__END__

=head1 SEE ALSO

L<SVN::Log::Index>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-svn-log@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Log>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

The current maintainer is Nik Clayton, <nikc@cpan.org>.

The original author was Garrett Rooney, <rooneg@electricjellyfish.net>.
Originally extracted from from SVN::Log::Index by Richard Clamp,
<richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2005 Nik Clayton.  All Rights Reserved.

Copyright 2004 Garrett Rooney.  All Rights Reserved.

Copyright 2004 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
