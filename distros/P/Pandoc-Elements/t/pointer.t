use 5.010001;
use strict;
use warnings;

use Test::More 0.96;
use Test::Exception;

use Pandoc::Elements;

# Make sure examples from  RFC 6901 sec 5 work as metadata

my $doc = pandoc_json(<<'JSON');
[ { "unMeta": {
    "":{"c":"0","t":"MetaString"},
    " ":{"c":"7","t":"MetaString"},
    "a/b":{"c":"1","t":"MetaString"},
    "c%d":{"c":"2","t":"MetaString"},
    "e^f":{"c":"3","t":"MetaString"},
    "foo":{"c":[
            {"c":[{"c":"bar","t":"Str"}],"t":"MetaInlines"},
            {"c":[{"c":"baz","t":"Str"}],"t":"MetaInlines"}
        ],"t":"MetaList"},
    "g|h":{"c":"4","t":"MetaString"},
    "i\\j":{"c":"5","t":"MetaString"},
    "k\"l":{"c":"6","t":"MetaString"},
    "m~n":{"c":"8","t":"MetaString"}
} }, [] ]
JSON

my @tests = (
    [   'RFC 6901' => [
            [ ""       => $doc->value ],
            [ "/foo"   => [ "bar", "baz" ] ],
            [ "/foo/0" => "bar" ],
            [ "/"      => 0 ],
            [ "/a~1b"  => 1 ],
            [ "/c%d"   => 2 ],
            [ "/e^f"   => 3 ],
            [ "/g|h"   => 4 ],
            [ "/i\\j"  => 5 ],
            [ "/k\"l"  => 6 ],
            [ "/ "     => 7 ],
            [ "/m~0n"  => 8 ],
        ],
    ],

    # If the 'pointer' string does not start with a forward
    # slash or is empty the whole string is a plain key.
    [   'plain-key' => [
            [ "foo"   => [ "bar", "baz" ] ],
            [ "foo/0" => undef ],
            [ "a/b"   => 1 ],
            [ "c%d"   => 2 ],
            [ "e^f"   => 3 ],
            [ "g|h"   => 4 ],
            [ "i\\j"  => 5 ],
            [ "k\"l"  => 6 ],
            [ " "     => 7 ],
            [ "m~n"   => 8 ],
        ],
    ],
);


for my $test ( @tests ) {
    my($name, $subtests) = @$test;
    subtest $name => sub {
        for my $subtest ( @$subtests ) {
            my ( $pointer, $expected ) = @$subtest;
            my $value = $doc->value( $pointer );
            is_deeply $value, $expected, "'$pointer'"
            or note explain { got => $value, expected => $expected };
            next unless defined $expected;
            lives_ok { $doc->value( $pointer, strict => 1 ) } "'$pointer' strict";
        }
    };
}

subtest strict => sub {
    my @tests = (
        [   '/foo/2' =>
              qr{\QList index 2 out of range in (sub)pointer "/2" in pointer "/foo/2"\E}
        ],
        [   '/foo/bar' =>
              qr{\QNode "/bar" not a valid list index in (sub)pointer "/bar" in pointer "/foo/bar"\E}
        ],
        [   '/quux' =>
              qr{\QNode "/quux" doesn't correspond to any key in (sub)pointer "/quux" in pointer "/quux"\E}
        ],
        [   'quux' =>
              qr{\QNode "quux" doesn't correspond to any key in (sub)pointer "quux" in pointer "quux"\E}
        ],
        [   '/e^f/g/h' =>
              qr{\QNo list or mapping "/g" in (sub)pointer "/g/h" in pointer "/e^f/g/h"\E}
        ],
    );
    for my $test ( @tests ) {
        my ( $pointer, $regex ) = @$test;
        throws_ok { $doc->value( $pointer, strict => 1 ) } $regex,
          "'$pointer' throws";
        # # For Pandoc::Metadata::Error
        # my $exception = $@;
        # isa_ok $exception, 'Pandoc::Metadata::Error', "'$pointer' exception";
        # is $exception->{pointer}, $pointer, "'$pointer' pointer";
        # note explain $exception->data;
    }
};

subtest indices => sub {
    my @list = map {; MetaString $_ } 0 .. 122;
    my %meta = ( long_list => MetaList \@list );
    my $doc = Document [ { unMeta => \%meta }, [] ];
    my @range = 90 .. 112;
    my @returns = map {; $doc->value("/long_list/$_") } @range;
    is scalar(@returns), 23, 'return list length' or note scalar @returns;
    is_deeply [ @returns ], [ @range ], 'correct return values';
};

done_testing;


__END__

---

   {
      "foo": ["bar", "baz"],
      "": 0,
      "a/b": 1,
      "c%d": 2,
      "e^f": 3,
      "g|h": 4,
      "i\\j": 5,
      "k\"l": 6,
      " ": 7,
      "m~n": 8
   }

   The following JSON strings evaluate to the accompanying values:

    ""           // the whole document
    "/foo"       ["bar", "baz"]
    "/foo/0"     "bar"
    "/"          0
    "/a~1b"      1
    "/c%d"       2
    "/e^f"       3
    "/g|h"       4
    "/i\\j"      5
    "/k\"l"      6
    "/ "         7
    "/m~0n"      8

my $doc = pandoc->parse( markdown => <<'END_OF_MD', '--standalone' );
---
foo:
- bar
- baz
'': 0
a/b: 1
c%d: 2
e^f: 3
g|h: 4
i\j: 5
k"l: 6
' ': 7
m~n: 8
...
END_OF_MD

say $doc->meta->to_json;

