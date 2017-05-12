package OpenPlugin::Authenticate;

# $Id: Authenticate.pm,v 1.17 2003/04/03 01:51:23 andreychek Exp $

use strict;
use OpenPlugin::Plugin();

use base qw( OpenPlugin::Plugin );
$OpenPlugin::Authenticate::VERSION = sprintf("%d.%02d", q$Revision: 1.17 $ =~ /(\d+)\.(\d+)/);

sub OP   { return $_[0]->{_m}{OP} }
sub type { return 'authenticate' }

sub authenticate {}

1;

__END__

=pod

=head1 NAME

OpenPlugin::Authenticate - Validate the identity of a user

=head1 SYNOPSIS

 $OP = OpenPlugin->new( config => { src => /etc/config.conf } );

 unless( $OP->authenticate->authenticate({ username => $username,
                                           password => $password,
                                         })) {

     $OP->exception->throw( "Invalid login attempt!" );
 }

=head1 DESCRIPTION

The Authenticate plugin provides an interface for authenticating users.  It
would often be used when you have a login screen at the beginning of an
application.  The functions provided by the Authenticate plugin would determine
whether or not the correct username and password were entered by the user.

=head1 METHODS

B<authenticate( \%params )>

Return true if the parameters specified a valid user, false if not. The
required parameters depend on the driver.  Generally, each driver takes a
'username' and 'password' parameter.  Depending on the security mechanism and
the datasource, there may be additional parameters you'll need to provide.

=head1 BUGS

None known.

=head1 TO DO

This plugin needs a lot of work.  This interface is a little "lean".  I'm not
sure yet, maybe thats how we want it.

All the drivers need to be modified to be able to read options from the config,
so a developer doesn't have to pass in excessive amounts of parameters upon
each authentication.

Do we want to take on users and groups?  I think it'd be useful, but can we do
it in a generic manner?

A lot more drivers need to be created.

=head1 SEE ALSO

See the individual driver documentation for settings and parameters specific to
that driver.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut
