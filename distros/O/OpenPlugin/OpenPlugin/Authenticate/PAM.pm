package OpenPlugin::Authenticate::PAM;

# $Id: PAM.pm,v 1.14 2003/04/03 01:51:24 andreychek Exp $

use strict;
use OpenPlugin::Authenticate();
use base          qw( OpenPlugin::Authenticate );
use Authen::PAM;

$OpenPlugin::Authenticate::PAM::VERSION = sprintf("%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/);


sub authenticate {
    my ($self, $args) = @_;

    $args->{service} ||= "passwd";

    my $pamh;
    my $ret=0;

    # This function is not mod_perl safe, we need to do something about the
    # nested sub
    sub checkpwd_conv_func {
       my @res;
       while ( @_ ) {
          my $code = shift;
          my $msg = shift;
          my $ans = "";

          $ans = $args->{username} if ($code == PAM_PROMPT_ECHO_ON() );
          $ans = $args->{password} if ($code == PAM_PROMPT_ECHO_OFF() );

          push @res, PAM_SUCCESS();
       }
       push @res, PAM_SUCCESS();
       return @res;
    }

    $self->OP->log->info( "Authenticating $args->{username}");
    if ( ref($pamh = new Authen::PAM($args->{service}, $args->{username},
                                    \&checkpwd_conv_func)) ) {
       if ($pamh->pam_authenticate()==0) {
          $ret=1;
       }
    }
    $pamh = 0;  # force Destructor (per docs) (invokes pam_close())

    $self->OP->log->info( "Authenticate returned ($ret)");

    return($ret);
}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Authenticate::PAM - PAM driver for the OpenPlugin::Authenticate
plugin

=head1 PARAMETERS

No parameters can be passed in to OpenPlugin's B<new()> method for this driver.
The following parameters are accepted via the B<authenticate()> method:

=over 4

=item * username

The username to authenticate.

=item * password

The password to verify.

=item * service

The name of the PAM service to use for the authentication.  If none is
provided, it defaults to "passwd".

=back

=head1 CONFIG OPTIONS

=over 4

=item * driver

PAM

=back

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
