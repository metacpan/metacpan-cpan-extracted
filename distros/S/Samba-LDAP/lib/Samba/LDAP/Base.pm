package Samba::LDAP::Base;

# Returned by Perl::MinimumVersion 0.11
require 5.006;

use warnings;
use strict;
use base qw(Class::Base);
use Samba::LDAP::Config;

our $VERSION = '0.05';

#
# Add Log::Log4perl to all our classes!!!!
#

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# init()
#
# Initialisation method called by the new() constructor and passing a
# reference to a hash array containing any configuration items specified
# as constructor arguments.  Should return $self on success or undef on
# error, via a call to the error() method to set the error message.
#
# We don't use the $config reference yet, still deciding how best to
# handle that.
#------------------------------------------------------------------------

sub init {
    my ( $self, $config ) = @_;

    # Do something with $config here later

    # let's read in smbldap.conf and smbldap_bind.conf and make them
    # available via $self in every new->();
    # smbldap.conf
    my $conf = Samba::LDAP::Config->new();
    $conf = $conf->read_conf( $conf->find_smbldap );

    # Stick them all in $self
    $self->{$_} = $conf->{$_} for keys %$conf;

    my $bind_conf = $conf->read_conf( $conf->find_smbldap_bind );

    # Same again
    $self->{$_} = $bind_conf->{$_} for keys %$bind_conf;

    return $self;
}

#------------------------------------------------------------------------
# module_version()
#
# Returns the current version number.
#------------------------------------------------------------------------

sub module_version {
    my $self = shift;
    my $class = ref $self || $self;
    no strict 'refs';
    return ${"${class}::VERSION"};
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Samba::LDAP::Base - Base class module implementing common functionality


=head1 VERSION

This document describes Samba::LDAP::Base version 0.05

=head1 SYNOPSIS

See L<Class::Base>

=head1 DESCRIPTION

Base class module which implements a constructor and error reporting 
functionality for various Samba-LDAP modules. Subclasses L<Class::Base>

B<DEVELOPER RELEASE!>

B<BE WARNED> - Not yet complete and neither are the docs!

=head1 INTERFACE

See L<Class::Base>

=head2 init

Used to read in our configuration files, on creation of new objects

=head2 module_version

Returns the current module version number. See L<Template::Base>
    
    my $module = Samba::LDAP->new();
    my $version = $module->module_version();


=head1 DIAGNOSTICS

See L<Class::Base>


=head1 CONFIGURATION AND ENVIRONMENT

Samba::LDAP::Base requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Class::Base>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-samba-ldap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gavin Henry  C<< <ghenry@suretecsystems.com> >>

=head1 ACKNOWLEDGEMENTS

IDEALX for original scripts.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2001-2002 IDEALX - Original smbldap-tools

Copyright (c) 2006, Suretec Systems Ltd. - Gavin Henry
C<< <ghenry@suretecsystems.com> >>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. See L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
