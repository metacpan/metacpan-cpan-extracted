# -*-perl-*-
###########################################################################
=pod

=head1 NAME

reaper - support for reaping child processes via $SIG{CHLD}

=head1 SYNOPSIS

  use reaper qw( reaper reapPid pidStatus );

  my $pid = fork;
  if ( $pid == 0 ) { # child
    exec $some_command;
  }
  reapPid ( $pid );

  ...

  if ( defined(my $exit = pidStatus($pid)) ) {
    # child exited, check the code...
  }


=head1 DESCRIPTION

reaper is just a backwards-compatibility wrapper for Reaper -- turns
out that only 'pragmas' are supposed to be named in lower case, so I
renamed reaper to Reaper.  But existing code contains 'use reaper', so
this allows such code to work without changes.

=cut
#'
###########################################################################

use strict;

package reaper;
use Reaper qw( reaper reapPid pidStatus );
@reaper::EXPORT = qw();
@reaper::EXPORT_OK = qw( reaper reapPid pidStatus );


###########################################################################
# End of package
###########################################################################
package main;
1;
__END__
=pod

=back

=head1 AUTHOR

Jeremy Slade E<lt>jeremy@jkslade.netE<gt>

=head1 SEE ALSO

L<Reaper>

=cut

