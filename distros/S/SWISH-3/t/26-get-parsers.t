#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Data::Dump qw( dump );

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new(), "new swish3" );
ok( my $parsers = $s3->get_config->get_parsers(), "get_parsers" );

# parsers are keyed like: mime => parser
#diag( dump $parsers->keys );

is( $parsers->get('text/plain'), 'TXT',  "text/plain => TXT" );
is( $parsers->get('default'),    'HTML', "default => HTML" );

# alter config. right now the only way is to merge xml
my $alt_parsers = <<XML;
<swish>
 <Parsers>
  <XML>application/x-foo</XML>
 </Parsers>
</swish>
XML

ok( $s3->config->merge($alt_parsers), "merge new alt_parsers" );
is( $parsers->get('application/x-foo'),
    'XML', "new application/x-foo parsers recognized" );

#diag( dump $parsers->keys );

is( $parsers->get('application/none-such'),
    undef, "get undef on unmapped mime" );
