#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/ACL/Group/GDBM_File.pm $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::ACL::Group::GDBM_File;
{
  $RPC::Serialized::ACL::Group::GDBM_File::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::ACL::Group::File';

use GDBM_File;
use RPC::Serialized::Exceptions;

sub hash {
    my $self = shift;

    unless ( $self->{HASH} ) {
        my $path = $self->path;

        my %hash;
        tie( %hash, 'GDBM_File', $path, GDBM_READER, 0 )
            or throw_system "Failed to open GDBM file $path: $!";

        $self->{HASH} = \%hash;
    }

    return $self->{HASH};
}

sub is_member {
    my $self = shift;
    my $name = shift;
    return exists $self->hash->{$name};
}

1;

