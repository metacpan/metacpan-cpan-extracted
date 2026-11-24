use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use PDL::Core;
use PDL::Types;

use PDL::IO::Protobuf qw(rprotobuf wprotobuf from_protobuf to_protobuf);

{
    package MockProtoVector;
    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }
    sub values {
        my ($self, $val) = @_;
        $self->{values} = $val if @_ > 1;
        return $self->{values};
    }
    sub serialize {
        my ($self) = @_;
        return pack('d*', @{ $self->{values} || [] });
    }
    sub parse {
        my ($class, $bytes) = @_;
        my @vals = unpack('d*', $bytes);
        return $class->new(values => \@vals);
    }
}

my $pdl = PDL::Core::pdl(PDL::Type->new('double'), [1.5, 2.5, 3.5, 4.5]);
my ($fh, $tmp) = tempfile('pdl_pb_XXXXXX', SUFFIX => '.pb', UNLINK => 1);
close $fh;

my $msg = wprotobuf($pdl, $tmp, 'MockProtoVector', 'values');
isa_ok($msg, 'MockProtoVector');

my $loaded = rprotobuf($tmp, 'MockProtoVector', 'values', proto_type => 'double', dims => [2, 2]);
is_deeply([ $loaded->dims ], [2, 2], 'reshaped to 2x2');
is_deeply([ $loaded->flat->list ], [1.5, 2.5, 3.5, 4.5], 'round-trip values match');

done_testing();
