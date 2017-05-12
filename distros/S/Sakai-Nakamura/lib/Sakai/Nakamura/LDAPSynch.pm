#!/usr/bin/perl -w

package Sakai::Nakamura::LDAPSynch;

use 5.008008;
use strict;
use warnings;
use Carp;
use base qw(Apache::Sling::LDAPSynch);
use Sakai::Nakamura;
use Sakai::Nakamura::Authn;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{ sub command_line
sub command_line {
    my ( $class, @ARGV ) = @_;
    my $nakamura = Sakai::Nakamura->new;
    my $config   = $class->config( $nakamura, @ARGV );
    my $authn    = new Sakai::Nakamura::Authn( \$nakamura );
    return $class->run( $nakamura, $config );
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::LDAPSynch - synchronize users from an external LDAP server into a Sakai Nakamura instance.

=head1 ABSTRACT

Synchronize users from an external LDAP server with the internal users
in a Sakai Nakamura instance.

=head1 METHODS

=head2 new

Create, set up, and return an LDAPSynch object.

=head2 synch_listed

Perform a synchronization of Sling internal users with the external LDAP users
for a set of users listed in a specified file.

=head2 ldap_connect

Connect to the ldap server.

=head2 ldap_search

Perform an ldap search.

=head2 init_synch_cache

Initialize the Sakai Nakamura synch cache.

=head2 get_synch_cache

Fetch the synchronization cache file.

=head2 update_synch_cache

Update the synchronization cache file with the latest state.

=head2 get_synch_user_list

Fetch the synchronization user list file.

=head2 update_synch_user_list

Update the synchronization user_list file with the latest state.

=head2 download_synch_user_list

Download the current synchronization user list file.

=head2 upload_synch_user_list

Upload a list of users to be synchronized into the sling system.

=head2 parse_attributes

Read the given ldap and sling attributes into two separate specified arrays.
Check that the length of the arrays match.

=head2 check_for_property_modifications

Compare a new property hash with a cached version. If any changes to properties
have been made, then return true. Else return false.

=head2 perform_synchronization

=head2 synch_full

Perform a full synchronization of Sling internal users with the external LDAP
users.

=head2 synch_full_since

Perform a synchronization of Sling internal users with the external LDAP users,
using LDAP changes since a given timestamp.

=head2 synch_listed_since

Perform a synchronization of Sling internal users with the external LDAP users,
using LDAP changes since a given timestamp for a set of users listed in a
specified file.

=head1 USAGE

use Sakai::Nakamura::LDAPSynch;

=head1 DESCRIPTION

Perl library providing a means to synchronize users from an external
LDAP server with the internal users in a Sakai Nakamura instance.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2012 Daniel David Parry <perl@ddp.me.uk>
