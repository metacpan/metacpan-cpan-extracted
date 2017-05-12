package Samba::LDAP;

# Returned by Perl::MinimumVersion 0.11
require 5.006;

use warnings;
use strict;
use Carp qw(carp croak);
use Regexp::DefaultFlags;
use Readonly;
use Net::LDAP;
use base qw( Samba::LDAP::Base );

our $VERSION = '0.05';

#
# Add Log::Log4perl to all our classes!!!!
#

# Add/Use for main code and tests:
#
# Net::LDAP::Util (DN stuff)
#
# Net::LDAP::Schema (read schemas, good to check if right ones are loaded)
#
# NET::LDAP::DSML (XML output)
#
# Net::LDAP::Extra (adding new features)

# Regexp for compiling
Readonly my $LOCALSID => qr{
                             ^SID      # Start of String
                             [ ]       # Character class for space
                             for 
                             [ ]       
                             domain
                             [ ] 
                             (\S+)     # Non-Whitespace
                             [ ]
                             is:
                             [ ] 
                             (\S+)$    # Non-Whitespace to end of line
                           };

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# get_local_sid()
#
# Tries to get the local Samba Domain SID, using:
# 'net getlocalsid'. If it fails, returns 'Can not find SID'
#------------------------------------------------------------------------

sub get_local_sid {
    my $self = shift;

    my $net_command = `LANG= \
                       PATH=/opt/IDEALX/bin:/usr/local/bin:/usr/bin:/bin \
                       net getlocalsid 2>/dev/null`;

    my ( $domain, $sid ) = $net_command =~ $LOCALSID;

    # More than likely a better way
    $self->{SID} = $sid;
    return $self->{SID} if $sid;

    # Set and return error
    $self->error('Can not find SID');
    return $self->error();
}

#------------------------------------------------------------------------
# does_sid_exist( $sid, $dn_group )
#
# Check there is a SID for user etc.
#------------------------------------------------------------------------

sub does_sid_exist {
    my $self     = shift;
    my $sid      = shift;
    my $dn_group = shift;

    my $ldap = $self->connect_ldap_master();
    my $mesg = $ldap->search(
        base   => $dn_group,
        scope  => $self->{scope},
        filter => "(sambaSID=$sid)"

#filter => "(&(objectClass=sambaSAMAccount|objectClass=sambaGroupMapping)(sambaSID=$sid))"
    );
    $mesg->code && die $mesg->error;
    return ($mesg);
}

#------------------------------------------------------------------------
# get_dn_from_line()
#
# dn = get_dn_from_line ($dn_line)
#------------------------------------------------------------------------

sub get_dn_from_line {
    my $self = shift;
    my $dn   = shift;

    # to get "a=b,c=d" from "dn: a=b,c=d"
    $dn =~ s{\A dn: [ ] }{};

    return $dn;
}

#------------------------------------------------------------------------
# do_ldapadd()
#
# Description here
#------------------------------------------------------------------------

sub do_ldapadd {
}

#------------------------------------------------------------------------
# do_ldapmodify()
#
# Description here
#------------------------------------------------------------------------

sub do_ldapmodify {
}

#------------------------------------------------------------------------
# connect_ldap_master()
#
# Connects to Master LDAP server listed in smbldap.conf. Returns Net:LDAP
# Object
#------------------------------------------------------------------------

sub connect_ldap_master {
    my $self = shift;

    # bind to a directory with dn and password
    my $ldap_master = Net::LDAP->new(
        $self->{masterLDAP},
        port    => $self->{masterPort},
        version => 3,
        timeout => 60,
    ) or die "LDAP Error: Can't contact master ldap server ($@)";

    my $ldap_tls;
    if ( $self->{ldapTLS} == 1 ) {
        $ldap_tls = $ldap_master->start_tls(
            verify     => $self->{verify},
            clientcert => $self->{clientcert},
            clientkey  => $self->{clientkey},
            cafile     => $self->{cafile},
        );

        # Check TLS has started before binding
        $ldap_tls->code && die 'Failed to start TLS: ', $ldap_tls->error;
    }

    my $result =
      $ldap_master->bind( $self->{masterDN}, password => $self->{masterPw}, );
    $result->code && die 'Bind error: ', $result->error, "\n";

    return $ldap_master;
}

#------------------------------------------------------------------------
# connect_ldap_slave()
#
# Connect to Slave LDAP Directory
#------------------------------------------------------------------------

sub connect_ldap_slave {
    my $self = shift;

    my $ldap_slave = Net::LDAP->new(
        $self->{slaveLDAP},
        port    => $self->{slavePort},
        version => 3,
        timeout => 60,

      )
      or carp "LDAP error: Can't contact slave ldap server ($@)\n
               =>trying to contact the master server\n";

    if ( !$ldap_slave ) {

        # connection to the slave failed: trying to contact the master ...
        $ldap_slave = Net::LDAP->new(
            $self->{masterLDAP},
            port    => $self->{masterPort},
            version => 3,
            timeout => 60,
        ) or die "LDAP error: Can't contact master ldap server ($@)\n";
    }

    if ($ldap_slave) {
        my $ldap_tls;
        if ( $self->{ldapTLS} == 1 ) {
            $ldap_tls = $ldap_slave->start_tls(
                verify     => $self->{verify},
                clientcert => $self->{clientcert},
                clientkey  => $self->{clientkey},
                cafile     => $self->{cafile},
            );

            # Check TLS has started before binding
            $ldap_tls->code && die 'Failed to start TLS: ', $ldap_tls->error;
        }

        my $result =
          $ldap_slave->bind( $self->{slaveDN}, password => $self->{slavePw}, );
        $result->code && die 'Bind error: ', $result->error, "\n";

        return $ldap_slave;
    }

    return;
}

#------------------------------------------------------------------------
# group_type_by_name()
#
# Description here
#------------------------------------------------------------------------

sub group_type_by_name {
}

#------------------------------------------------------------------------
# list_union()
#
# Description here
#------------------------------------------------------------------------

sub list_union {
}

#------------------------------------------------------------------------
# list_minus()
#
# Description here
#------------------------------------------------------------------------

sub list_minus {
}

#========================================================================
#                         -- PRIVATE METHODS --
#========================================================================

1;    # Magic true value required at end of module
__END__

=head1 NAME

Samba::LDAP - Manage a Samba PDC with an LDAP Backend


=head1 VERSION

This document describes Samba::LDAP version 0.05


=head1 SYNOPSIS

    use Carp;
    use Samba::LDAP;
    
    my $samba = Samba::LDAP->new()
    or croak "Can't create object\n";
    my $domain = $samba->get_local_sid();


=head1 DESCRIPTION

Main functions.

B<DEVELOPER RELEASE!>

B<BE WARNED> - Not yet complete and neither are the docs!

=head1 INTERFACE 

=head2 new

Creates a new L<Samba::LDAP> object

=head2 get_local_sid

Tries to find Samba Domain SID, if not, returns undef.

=head2 does_sid_exist



=head2 get_dn_from_line



=head2 do_ldapadd



=head2 do_ldapmodify



=head2 get_user_dn2



=head2 connect_ldap_master



=head2 connect_ldap_slave



=head2 group_type_by_name



=head2 subst_configvar



=head2 read_config



=head2 read_parameter



=head2 split_arg_comma



=head2 list_union



=head2 list_minus



=head2 get_next_id



=head2 print_banner



=head2 get_domain_name



=head1 DIAGNOSTICS

None yet.


=head1 CONFIGURATION AND ENVIRONMENT

Samba::LDAP requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Carp>
L<Regexp::DefaultFlags>
L<Readonly>
L<Net::LDAP>


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
