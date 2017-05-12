#
# $HeadURL: https://svn.oucs.ox.ac.uk/people/oliver/pub/librpc-serialized-perl/trunk/lib/RPC/Serialized/ACL/Group/File.pm $
# $LastChangedRevision: 1281 $
# $LastChangedDate: 2008-10-01 16:16:56 +0100 (Wed, 01 Oct 2008) $
# $LastChangedBy: oliver $
#
package RPC::Serialized::ACL::Group::File;
{
  $RPC::Serialized::ACL::Group::File::VERSION = '1.123630';
}

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::ACL::Group';

use IO::File;
use UNIVERSAL;
use RPC::Serialized::Exceptions;

sub new {
    my $class = shift;
    my $uri   = shift;

    defined $uri and UNIVERSAL::isa( $uri, 'URI::file' )
        or throw_app 'Missing or invalid URI';

    my $path = $uri->file
        or throw_app "Can't determine path from URI " . $uri->as_string;

    return bless {
        PATH => $path,
    }, $class;
}

sub path {
    my $self = shift;
    return $self->{PATH};
}

sub is_member {
    my $self = shift;
    my $name = shift;

    my $path = $self->path;
    my $fh   = IO::File->new( $path, O_RDONLY )
        or throw_system "Failed to open $path: $!";

    while (<$fh>) {
        s/#.*$//;
        s/^\s+//;
        s/\s+$//;
        next unless length($_);
        return 1 if $_ eq $name;
    }

    return 0;
}

1;

