package OpenPlugin::Authenticate::SMB;

# $Id: SMB.pm,v 1.13 2003/04/03 01:51:24 andreychek Exp $

use strict;
use OpenPlugin::Authenticate();
use base          qw( OpenPlugin::Authenticate );
use Authen::Smb;

use constant SMB_NO_ERROR       => 0;
use constant SMB_SERVER_ERROR   => 1;
use constant SMB_PROTOCOL_ERROR => 2;
use constant SMB_LOGON_ERROR    => 3;

$OpenPlugin::Authenticate::SMB::VERSION = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);


# Okay, slurped up this code from OI, but still needs tested :-)

# Authenticate a user via SMB
sub authenticate {
    my ($self, $args) = @_;

    my $authResult = Authen::Smb::authen($args->{username},
                                         $args->{password},
                                         $args->{pdc},
                                         $args->{bdc},
                                         $args->{ntdomain});

    $self->OP->log->info( "Trying to check SMB password for ",
                    "($args->{username}) using",
                    "PDC: $args->{pdc}; BDC: $args->{bdc}; ",
                    "DOMAIN: $args->{domain}";

    # Sucess!
    return 1 if ( $rv == SMB_NO_ERROR );

    my $error_status = undef;
    $error_status = "Logon Error"    if ( $rv == SMB_LOGON_ERROR );
    $error_status = "Server Error"   if ( $rv == SMB_SERVER_ERROR );
    $error_status = "Protocol Error" if ( $rv == SMB_PROTOCOL_ERROR );
    DEBUG && $self->OP->log->info( "Error found trying to login: $error_status" );

    return 0;

}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Authenticate::SMB - SMB driver for the OpenPlugin::Authenticate
plugin

=head1 PARAMETERS

No parameters can be passed in to OpenPlugin's B<new()> method for this driver.
The following parameters are accepted via the B<authenticate()> method:

=over 4

=item * username

The username to authenticate.

=item * password

The password to verify.

=item * pdc

The NT name of the primary domain controller to authenticate against.

=item * bdc

The NT name of the backup domain controller to authenticate against.

=item * ntdomain

The name of your domain.

=back

=head1 CONFIG OPTIONS

=over 4

=item * driver

PAM

=back

head1 TO DO

Nothing known.

=head1 BUGS

I'm not quite sure it even works. I copied and pasted the code from the
Authen::SMB POD, so there's a fair chance it's just my configuration that isn't
working right.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
