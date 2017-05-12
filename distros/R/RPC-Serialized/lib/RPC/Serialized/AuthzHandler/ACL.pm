#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/AuthzHandler/ACL.pm $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::AuthzHandler::ACL;
{
  $RPC::Serialized::AuthzHandler::ACL::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::AuthzHandler';

use Readonly;
use IO::File;
use RPC::Serialized::ACL;
use RPC::Serialized::ACL::Group;
use RPC::Serialized::Exceptions;

Readonly my $GROUP_RX => qr/^define\s+group\s+(\S+)\s+(.+)$/;
Readonly my $ACL_RX   => qr/^(allow|deny)\s+(\S+)\s+by\s+(\S+)\s+on\s+(\S+)$/;

sub _parse_acls {
    my $acl_path = shift;

    my $acl_fh   = IO::File->new($acl_path)
        or throw_system "Open $acl_path failed: $!";

    my ( @acls, %groups );
    while (<$acl_fh>) {
        s/#.*$//;
        s/^\s+//;
        s/\s+$//;
        next unless length($_);

        if ( my ( $action, $operation, $subject, $target ) = $_ =~ $ACL_RX ) {
            if ( $subject =~ s/^group:// ) {
                $subject = $groups{$subject}
                    or throw_app
                        "Reference to undefined group at '$acl_path' line $.";
            }
            if ( $target =~ s/^group:// ) {
                $target = $groups{$target}
                    or throw_app
                        "Reference to undefined group at '$acl_path' line $.";
            }
            push @acls,
                RPC::Serialized::ACL->new(
                    operation => $operation,
                    subject   => $subject,
                    target    => $target,
                    action    => $action,
                );
        }
        elsif ( my ( $name, $uri ) = $_ =~ $GROUP_RX ) {
            $groups{$name} = RPC::Serialized::ACL::Group->new($uri);
        }
        else {
            throw_app "Failed to parse ACLs at '$acl_path' line $.";
        }
    }

    return \@acls;
}

sub new {
    my $class    = shift;

    my $acl_path = shift
        or throw_app 'ACL path not specified';

    return bless {
        ACLS => _parse_acls($acl_path),
    }, $class;
}

sub acls {
    my $self = shift;
    $self->{ACLS};
}

sub check_authz {
    my $self = shift;
    my ( $subject, $operation, $target ) = @_;

    foreach my $acl ( @{ $self->acls } ) {
        my $rc = $acl->check( $subject, $operation, $target );
        next if $rc == $acl->DECLINE;
        return $rc == $acl->ALLOW ? 1 : 0;
    }

    return 0;
}

1;

