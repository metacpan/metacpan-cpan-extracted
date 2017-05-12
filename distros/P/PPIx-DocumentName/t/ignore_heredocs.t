use strict;
use warnings;

use Test::More tests => 4;

# ABSTRACT: Make sure heredocs aren't parsed

use PPIx::DocumentName;
use PPI::Util qw( _Document );

my $sample = <<'EOF';
package Foo::Bar;

my $value = <<'XXX';

# PODNAME: Bogus

XXX

1;
EOF

{
  my $result = _Document( \$sample );
  isa_ok( $result, 'PPI::Document', "_Document(\\\$sample)" );
};

{
  my $result = PPIx::DocumentName->extract( \$sample );
  is( $result, 'Foo::Bar', "->extract() is package statement" );
}

{
  my $result = PPIx::DocumentName->extract_via_statement( \$sample );
  is( $result, 'Foo::Bar', "->extract_via_statement() is expected value" );
}
{
  my $result = PPIx::DocumentName->extract_via_comment( \$sample );
  is( $result, undef, "->extract_via_comment() is undef" );
}
