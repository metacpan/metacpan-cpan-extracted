#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/ACL/Group.pm $
# $LastChangedRevision: 1326 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::ACL::Group;
{
  $RPC::Serialized::ACL::Group::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use URI;
use Readonly;
use RPC::Serialized::Exceptions;

Readonly my %schemes => (
    'file' => sub {
        my $uri = shift;

        return 'RPC::Serialized::ACL::Group::GDBM_File'
            if $uri->file =~ /\.gdbm$/;

        return 'RPC::Serialized::ACL::Group::File';
    }
);

sub new {
    my $proto = shift;
    my $str   = shift
        or throw_app 'URI not specified';

    my $uri = URI->new($str)
        or throw_app "Failed to parse URI '$str'";

    my $scheme = $uri->scheme
        or throw_app "Failed to parse scheme from URI '$str'";

    my $map = $schemes{$scheme}
        or throw_app "Unsupported URI scheme '$scheme'";

    my $class = $map->($uri);
    eval "require $class"
        or throw_system "Failed to load '$class': $!";

    return $class->new($uri);
}

sub is_member {
    my $self = shift;
    my $name = shift;
    return;
}

sub match {
    my $self = shift;
    my $name = shift;
    return defined($name) && $self->is_member($name);
}

1;

