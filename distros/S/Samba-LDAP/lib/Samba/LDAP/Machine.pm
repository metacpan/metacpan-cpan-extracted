package Samba::LDAP::Machine;

# Returned by Perl::MinimumVersion 0.11
require 5.006;

use warnings;
use strict;
use Carp qw(carp croak);
use Readonly;
use Regexp::DefaultFlags;
use Crypt::SmbHash;
use base qw(Samba::LDAP::Base);

our $VERSION = '0.05';

#
# Add Log::Log4perl to all our classes!!!!
#

# Our usage messages
Readonly my $ADD_POSIX_MACHINE_USAGE => 
        'Usage: add_posix_machine( 
               host => \'linux1\', uid => \'1015\', gid => \'1015\', );';

#========================================================================
#                         -- PUBLIC METHODS --
#========================================================================

#------------------------------------------------------------------------
# add_posix_machine()
#
# Add a workstation to the Directory
#------------------------------------------------------------------------

sub add_posix_machine {
    my $self = shift;
    my %machine_args = (
        time_to_wait => 0,
        @_,    # argument pair list goes here
    );

    my $host = $machine_args{host};
    my $uid  = $machine_args{uid};
    my $gid  = $machine_args{gid};
    my $wait = $machine_args{time_to_wait};

    # Required arguments
    my @required_args = ( $host, $uid, $gid );
    croak $ADD_POSIX_MACHINE_USAGE
        if any {!defined $_} @required_args;

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master(); 

    my $add = $ldap->add ( "uid=$host,$self->{computersdn}",
                                  attr => [
                                           'objectclass' => ['top', 'person',
'organizationalPerson', 'inetOrgPerson', 'posixAccount'],
                                           'cn'   => "$host",
                                           'sn'   => "$host",
                                           'uid'   => "$host",
                                           'uidNumber'   => "$uid",
                                           'gidNumber'   => "$gid",
                                           'homeDirectory'   => '/dev/null',
                                           'loginShell'   => '/bin/false',
                                           'description'   => 'Computer',
                                           'gecos'   => 'Computer',
                                          ]
                                );
    
    $add->code && warn "failed to add entry: ", $add->error ;
    
    # take the session down
    $add->unbind;

    sleep($wait);
    return 1;
}

#------------------------------------------------------------------------
# add_samba_machine( $host, $uid )
#
# Add a workstation to the Domain
#------------------------------------------------------------------------

sub add_samba_machine {
    my $self = shift;
    my $host = shift;
    my $uid  = shift;

    my $sambaSID = 2 * $uid + 1000;
    my ($name) = $host =~ s/.$//s;

    my ($lmpassword,$ntpassword) = ntlmgen $name;   

    my $ldap = Samba::LDAP->new();
    $ldap = $ldap->connect_ldap_master(); 

    my $modify = $ldap->modify ( "uid=$host,$self->{computersdn}",
                                        changes => [
                                                    replace => [objectClass => ['inetOrgPerson', 'posixAccount', 'sambaSAMAccount']],
                                                    add => [sambaPwdLastSet => '0'],
                                                    add => [sambaLogonTime => '0'],
                                                    add => [sambaLogoffTime => '2147483647'],
                                                    add => [sambaKickoffTime => '2147483647'],
                                                    add => [sambaPwdCanChange => '0'],
                                                    add => [sambaPwdMustChange => '0'],
                                                    add => [sambaAcctFlags => '[W          ]'],
                                                    add => [sambaLMPassword => "$lmpassword"],
                                                    add => [sambaNTPassword => "$ntpassword"],
                                                    add => [sambaSID => "$self->{SID}-$sambaSID"],
                                                    add => [sambaPrimaryGroupSID => "$self->{SID}-0"]
                                                   ]
                                      );
    
    $modify->code && die "failed to add entry: ", $modify->error ;

    return 1;
}

#------------------------------------------------------------------------
# add_samba_machine_smbpasswd()
#
# Set the workstations password
#------------------------------------------------------------------------

sub add_samba_machine_smbpasswd {
    my $self = shift;
}

1;    # Magic true value required at end of module

__END__

=head1 NAME

Samba::LDAP::Machine - Manipulate Samba LDAP Machines (computers)

=head1 VERSION

This document describes Samba::LDAP::Machine version 0.05


=head1 SYNOPSIS

    use Carp;
    use Samba::LDAP::Machine;

    my $machine = Samba::LDAP::Machine->new()
        or croak "Can't create object\n";

=head1 DESCRIPTION

Various methods to add Samba LDAP Machines (computers)

B<DEVELOPER RELEASE!>

B<BE WARNED> - Not yet complete and neither are the docs!

=head1 INTERFACE 

=head2 new

Create a new L<Samba::LDAP::Machine> object

=head2 add_posix_machine

Add a workstation to the Directory

    
    my $result = $machine->add_posix_machine( {
                                                host => 'linux1', 
                                                uid => '1015', 
                                                gid => '1015',
                                            }
                                          );
    print "linux1 added\n" if $result;

=head2 add_samba_machine

Add a workstation to the Domain
    
    my $result = $machine->add_samba_machine( $host, $uid );
    print "$host added\n" if $result;

=head2 add_samba_machine_smbpasswd

Set the workstations password. Not complete.

=head1 DIAGNOSTICS

None yet.


=head1 CONFIGURATION AND ENVIRONMENT

Samba::LDAP::Machine requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Carp>,
L<Crypt::SmbHash> and
L<Regexp::DefaultFlags>

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
