#!/usr/local/bin/perl
#
#  Listgroup module
#
#  $Id: Listgroup.pm,v 1.16 2003-01-21 12:24:09-05 mprewitt Exp $
#
#  -----

=head1 NAME 

B<Listgroup.pm> - Lists hosts/users in a netgroup group.

=head1 SYNOPSIS

    use Listgroup;

    $array_ref_groups = listgroup();
    $array_ref_groups = listgroups();

    $array_ref_users_or_groups = listgroup({groupname});

    $array_ref_users_or_groups = listgroup_user({groupname1}, 
            [ [-]{groupname2}, [-]{gropuname3} ]);

    $array_ref_users_or_groups = listgroup_host({groupname1}, 
            [ [-]{groupname2}, [-]{gropuname3} ]);

=head1 DESCRIPTION

A library used to get groups or members of a netgroup NIS map.  
B<listgroup()> without any parameters or B<listgroups()> lists all 
the available netgroup groups.

With groupname parameters B<listgroup, listgroup_user, listgroup_host> will 
recusively list the members of the named groups.  If the groupname is preceded with
a B<-> members of that group will be excluded from the returned list.  Each member 
in a group is a triplet of (host,user,domain).  The host portion or user portion 
of the members is returned by B<listgroup_host()> and B<listgroup()>, 
the user portion of the members is returned by B<listgroup_user()>.

=head1 REQUIRES

Net::NIS

=head1 SEE ALSO

L<netgroup(4)>, L<listgroup(1)>, L<Net::NIS(3)>

=head1 AUTHOR

Original unknown

Major rewrite by Marc Prewitt <mprewitt@chelsea.net>

Copyright (C) 2003 Chelsea Networks, under the GNU GPL.
listgroup comes with ABSOLUTELY NO WARRANTY. This is free software, and you are
welcome to redistribute it under certain conditions; see the COPYING file 
for details.

listgroup is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

listgroup is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

=head1 PUBLIC METHODS

=cut

package Net::NIS::Listgroup;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(listgroup);
use strict;

use Net::NIS qw( :all );
use vars qw( $VERSION $DOMAIN );

$DOMAIN = Net::NIS::yp_get_default_domain();

my $YPCAT = '/usr/bin/ypcat';

$VERSION = (qw $Revision: 1.16 $)[1];

=head2 listgroups

    $array_ref_groups = listgroups();

Returns a reference to an array of groups from the netgroup nis map.

=cut
sub listgroups {
    my %netgroup;
    tie %netgroup, 'Net::NIS', 'netgroup';
    return [ sort keys %netgroup ];
}

=head2 listgroup_host, listgroup

    $array_ref_users_or_groups = listgroup({groupname1}, 
            [ [-]{groupname2}, [-]{gropuname3} ]);

    $array_ref_users_or_groups = listgroup_host({groupname1}, 
            [ [-]{groupname2}, [-]{gropuname3} ]);

Returns a reference to an array of the host portion of the members of the provided groups.  
Members of groupnames preceded by a B<-> will be excluded from the returned list.

Groups are processed in the order they appear in the parameter list.

If the NIS map 'netgroup' does not exist or another fatal NIS error
occurs, die will be called.  Wrap this call in an eval if you want 
to catch that type of error.

=cut
sub listgroup_host {
    my $r = Net::NIS::Listgroup::Request->new();
    $r->setHost();
    return $r->_listgroup(@_);
}

sub listgroup {
    my $r = Net::NIS::Listgroup::Request->new();
    $r->setHost();
    return $r->_listgroup(@_);
}

=head2 listgroup_user

    $array_ref_users_or_groups = listgroup_user({groupname1}, 
            [ [-]{groupname2}, [-]{gropuname3} ]);

Returns a reference to an array of the user portion of the members of the provided groups.  
Members of groupnames preceded by a B<-> will be excluded from the returned list.

Groups are processed in the order they appear in the parameter list.

If the NIS map 'netgroup' does not exist or another fatal NIS error
occurs, die will be called.  Wrap this call in an eval if you want 
to catch that type of error.

=cut
sub listgroup_user {
    my $r = Net::NIS::Listgroup::Request->new();
    $r->setUser();
    return $r->_listgroup(@_);
}

#======================================================================

package Net::NIS::Listgroup::Request;

use Net::NIS qw( :all );

my $YPMATCH = '/usr/bin/ypmatch';

#
#  new returns an object used to encapsulate options passed in the
#  original request.  
#
sub new {
    my $type = shift;
    $type = ref($type) if ref($type);
    return bless {}, $type;
}

#
#  $request->setHost()
#
#  This requset will return host information
#
sub setHost {
    my $self = shift;
    $self->{user} = 0;
    return $self->{host} = 1;
}

#
#  $request->setUser()
#
#  This request will return user information
#
sub setUser {
    my $self = shift;
    $self->{host} = 0;
    return $self->{user} = 1;
}

#
#  $want_user = $request->getUser()
#
#  Whether the user field is wanted in the request.
#
sub getUser {
    my $self = shift;
    return $self->{user};
}

#
#  $request->_listgroup( @groups )
#
#  Returns a arrayref of members contained or not contained
#  in @groups.  If a group starts with a '-' it's members
#  will be excluded from the list.
#
sub _listgroup {
    my $r = shift;
    my @args = @_;

    my ( %returns );

    foreach my $netgroup (@args) {
        my $subtract;
        if ( $netgroup =~ s/^-// ) {
            $subtract = 1;
        }
        my ($status, $members) = Net::NIS::yp_match($Net::NIS::Listgroup::DOMAIN, 'netgroup', $netgroup);
        die "Unknown netgroup: $netgroup [$Net::NIS::yperr]\n" unless $status == YPERR_SUCCESS;

        $members =~ s/#.*//;   # remove comments

        foreach my $member ( split(/\s+/, $members) ) {
            if ($member =~ s/^\(//) {
                $member =~ s/\)$//;
                my ($host, $user, $domain) = split(/,/, $member);
                if ($r->getUser()) {
                    if ($subtract) {
                        delete $returns{$user};
                    } else {
                        $returns{$user} = $user if $user;
                    }
                } else {
                    if ($subtract) {
                        delete $returns{$host};
                    } else {
                        $returns{$host} = $host if $host;
                    }
                }
            } else {
                foreach my $thing (@{$r->_listgroup($member) || []}) {
                    if ($subtract) {
                        delete $returns{$thing};
                    } else {
                        $returns{$thing} = $thing if $thing;
                    }
                }
            }
        }
    }
    return [sort keys %returns];
}

1;
