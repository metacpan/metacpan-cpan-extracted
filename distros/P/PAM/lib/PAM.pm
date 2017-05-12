package PAM;
{
  $PAM::VERSION = '0.31';
}

=head1 NAME

PAM - Invoke perl code at PAM phases

=head1 VERSION

version 0.31

=head1 SYNOPSIS

  package Example::PAM;
  
  use PAM::Constants qw(PAM_SUCCESS);
  use PAM::Handle;
  
  sub open_session {
    my $class = shift;
    my ($pamh, $flags, @ARGS) = @_;
    my $user = $pamh->get_user($prompt);
    
    return PAM_SUCCESS;
  }

=head1 DESCRIPTION

This Perl and PAM module allow you to invoke a perl interpreter and call package
methods during pam phases. It also includes bindings for most of the pam functions
and constants.

=head1 STATUS

Most of the interface is working at this point. I expect to be compatible at this
point with both Linux PAM and OSX (Darwin) PAM. The major functions in pam_*
should all be working. Some of the pam_{get,set}_item items are not implemented yet.

I wouldn't call this module secure just yet. I will mark version 1.0 when I feel
that is the case.

This all said, the module is safe enough to be used. It should be cleaning up all
memory that it consumes and barring mistakes in the perl code it invokes there
should be no chance of it causing unexpected failures.

=cut

require 5.008001;
use parent qw(DynaLoader);

sub dl_load_flags {0x01}

__PACKAGE__->bootstrap($VERSION);

1;

=head1 COPYRIGHT

Copyright 2012 - Jonathan Steinert

=head1 AUTHOR

Jonathan Steinert

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
