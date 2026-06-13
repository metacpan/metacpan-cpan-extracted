use warnings;
use strict;

use Benchmark qw(cmpthese);
use Data::Dumper;
use IPC::Shareable;
use JSON::XS;
use Storable qw(freeze thaw);

die "need run count\n" if ! $ARGV[0];

# Compares storing/fetching a small nested structure four ways: JSON or Storable
# serialization, into either a /dev/shm memfile or an IPC::Shareable tied scalar.
# The two *_share arms mirror how RPi::WiringPi::Meta keeps the whole blob as a
# single serialized string in one IPC::Shareable segment (one tie per
# serializer). destroy => 1 so the benchmark removes its own segments on exit.

my ($json_blob, $stor_blob);

tie $json_blob, 'IPC::Shareable', {
    key        => 'bshj',
    create     => 1,
    destroy    => 1,
    serializer => 'json',
} or die "can't tie json share: $!";

tie $stor_blob, 'IPC::Shareable', {
    key        => 'bshs',
    create     => 1,
    destroy    => 1,
    serializer => 'storable',
} or die "can't tie storable share: $!";

my $f = '/dev/shm/data';

cmpthese $ARGV[0], {
    json_file  => \&json_file,
    json_share => \&json_share,
    stor_file  => \&stor_file,
    stor_share => \&stor_share,
};

sub json_file {
    my $p = {a => 1, b => 'string', c => {x => 'this', y => 'that'}};
    open my $fh, '>', $f or die $!;
    print $fh encode_json($p);
    close $fh;

    {
        local $/;
        open $fh, '<', $f or die $!;
        $p = decode_json <$fh>;
        close $fh;
    }
    open $fh, '>', $f or die $!;
    print $fh encode_json($p);
    close $fh;
}
sub json_share {
    my $p = {a => 1, b => 'string', c => {x => 'this', y => 'that'}};
    $json_blob = encode_json $p;
    $p = decode_json $json_blob;
    $json_blob = encode_json $p;
}
sub stor_file {
    my $p = {a => 1, b => 'string', c => {x => 'this', y => 'that'}};
    open my $fh, '>', $f or die $!;
    print $fh freeze($p);
    close $fh;

    {
        local $/;
        open $fh, '<', $f or die $!;
        $p = thaw <$fh>;
        close $fh;
    }
    open $fh, '>', $f or die $!;
    print $fh freeze($p);
    close $fh;
}
sub stor_share {
    my $p = {a => 1, b => 'string', c => {x => 'this', y => 'that'}};
    $stor_blob = freeze $p;
    $p = thaw $stor_blob;
    $stor_blob = freeze $p;
}

__END__

# perl shareable_vs_memfile.pl 100000
#
# IPC::Shareable double-serializes a stored scalar (it wraps and re-encodes the
# string we hand it), so the *_share arms pay one extra serialize/parse pass
# versus the raw memfile arms. Run on your target Pi to get representative
# numbers for the JSON-into-IPC::Shareable path that Meta.pm actually uses.
