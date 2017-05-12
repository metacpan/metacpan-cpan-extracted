# Copyright (c) 2008 Yahoo! Inc.  All rights reserved.  The
# copyrights to the contents of this file are licensed under the Perl
# Artistic License (ver. 15 Aug 1997)

######################################################################
# Test suite for PHP::HTTPBuildQuery
######################################################################
use warnings;
use strict;

use PHP::HTTPBuildQuery qw(http_build_query http_build_query_utf8);
use Test::More;
use URI::Escape;

 # We rely on keys() returning the keys of a hash in a reproducable order
 # within the process, see http://perlmonks.org/?node_id=1056280 and
 # https://github.com/mschilli/php-httpbuildquery-perl/pull/3 for details.

 # According to https://rt.cpan.org/Public/Bug/Display.html?id=89278 we need
 # to set the environment variables
 #   PERL_HASH_SEED:    "0"
 #   PERL_PERTURB_KEYS: "NO"
 # and do that *before* the interpreter starts, so let's do that 
 # here and re-invoke ourselves.
if( !exists $ENV{ PERL_PERTURB_KEYS } ) {
    # warn "Re-invoking to set anti-hash-jumbling variables";
    $ENV{ PERL_PERTURB_KEYS } = "NO";
    $ENV{ PERL_HASH_SEED }    = "0";
    exec $^X, $0, @ARGV or die;
}

plan tests => 14;

is( http_build_query( 
      { foo => { 
          bar   => "baz", 
          quick => { "quack" => "schmack" },
        },
      },
    ),
    cobble("foo[bar]=baz", "foo[quick][quack]=schmack", 
       ['bar', 'quick']),
    "pod"
);

is( http_build_query( ['foo', 'bar'], "name" ),
    "name_0=foo&name_1=bar",
    "array at top level"
);

is( http_build_query( ['foo', 'bar'] ),
    "0=foo&1=bar",
    "array at top level"
);

is( http_build_query( { foo => "bar" } ), 
    "foo=bar",
    "simple hash"
);

is( http_build_query( { foo => { "bar" => "baz" }} ), 
    cobble("foo[bar]=baz"),
    "nested hash"
  );

is( http_build_query( { foo => { "bar" => { quick => "quack" }}} ), 
    cobble("foo[bar][quick]=quack"),
    "nested hash"
  );

is( http_build_query( { foo => "bar", "baz" => "quack" } ),
    cobble("foo=bar", "baz=quack", ['foo', 'baz']),
    "two elements"
  );

is( http_build_query( { foo => "bar", "baz" => "quack", "me" => "you" } ),
    cobble("foo=bar", "baz=quack", "me=you",
           ['foo', 'baz', 'me']),
    "three elements"
  );

is( http_build_query( { "foo%" => "bar" } ),
    "foo%25=bar",
    "urlesc in key"
  );

is( http_build_query( { "foo" => "ba%r" } ),
    "foo=ba%25r",
    "urlesc in value"
  );

is( http_build_query( { a => "b", c => { d => "e" } }, "foo" ),
    cobble("a=b", "c[d]=e", ['a', 'c']),
    "nested struct"
  );

is( http_build_query( { a => { 'b' => undef }, c => undef } ),
    cobble("a[b]=", "c=", ['a', 'c']),
    'undefined scalars'
  );

is( http_build_query( 'id' ),
    '=id',
    'undefined sofar'
  );

use utf8;

is( http_build_query_utf8( ["\x{2013}foo", 'bar'] ),
    "0=%E2%80%93foo&1=bar",
    "utf8 char in array"
);

###########################################
sub cobble {
###########################################
    my(@fields) = @_;

    my $sort_order;

    if(ref ( $fields[-1] ) eq "ARRAY" ) {
        $sort_order = pop @fields;
    }

    @fields = hashsort(\@fields, $sort_order) if defined $sort_order;

    return join '&', map { escape_brackets( $_ ) } @fields;
}

###########################################
sub hashsort {
###########################################
    my($array, $hash_keys) = @_;

    my $i=0;
    my %order_hash = map { $_ => $i++ } @$hash_keys;

    my @copy = ();

    for my $key (keys %order_hash) {
        push @copy, $array->[ $order_hash{ $key } ];
    }

    return @copy; 
}

###########################################
sub escape_brackets {
###########################################
    local($_) = $_[0];
    s/\[/%5B/g;
    s/\]/%5D/g;
    return $_;
}
