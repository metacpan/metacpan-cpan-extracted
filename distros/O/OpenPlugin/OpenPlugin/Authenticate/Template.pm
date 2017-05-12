package OpenPlugin::Authenticate::Template;

# $Id: Template.pm,v 1.11 2003/04/03 01:51:24 andreychek Exp $

# This is a template for an authentication driver.  You can use this as a base
# for creating new drivers that authenticate your users against a particular
# text file, database, or whatever else you can think up.  The only sub you
# have to create is 'authenticate'.

use strict;
use OpenPlugin::Authenticate();
use base          qw( OpenPlugin::Authenticate );

$OpenPlugin::Authenticate::Template::VERSION = sprintf("%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/);

sub authenticate {
    my ($self, $args) = @_;

    $self->OP->log->info( "Authenticating $args->{username}");

    # Use the arguments sent in via the hashref $args to authenticate a user
    # via some means.  Return true if they succesfully authenticated, false
    # otherwise.

}


1;

__END__

=pod

=head1 NAME

OpenPlugin::Authenticate::Template - Sample template for creating a OpenThought
Authentication driver.

=head1 PARAMETERS

No parameters can be passed in to OpenPlugin's B<new()> method for this driver.
The following parameters are accepted via the B<authenticate()> method:

=over 4

=item * username

The username to authenticate.

=item * password

The password to verify.

=item * <others>

List additional parameters your driver offers here.

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
