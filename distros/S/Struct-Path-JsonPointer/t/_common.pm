package _common;

# common parts for Struct::Path::JsonPointer tests

use parent 'Exporter';

use Clone qw(clone);
use Data::Dumper qw();
use Struct::Path::JsonPointer qw(str2path path2str);
use Test::More;

our @EXPORT_OK = qw(
    roundtrip
    t_dump
);

sub roundtrip {
    my ($struct, $string, $comment) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $orig_string = $string;
    my $orig_struct = clone($struct);

    my $serialized = path2str($struct);
    my $parsed = str2path($serialized);

    subtest $comment => sub {
        plan tests => 4;

        is_deeply($struct, $parsed, "$comment: parsing");
        is($string, $serialized, "$comment: serialization");

        is_deeply($orig_struct, $struct, "$comment: input struct changed");
        is($orig_string, $string, "$comment: input string changed");
    }
}

# return neat one-line string of perl serialized structure
sub t_dump {
    return Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
}

1;
