use strict;
use warnings;
use Test::More;
use PPIx::DocumentName;
use PPI::Util qw( _Document );

subtest 'Basic tests' => sub {

  my $sample = <<'EOF';
package Foo::Bar;

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
    my @result = PPIx::DocumentName->extract( \$sample );
    is_deeply( \@result, ['Foo::Bar'], "->extract() is package statement (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    is( $result, 'Foo::Bar', "->extract_via_statement() is correct" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    is_deeply( \@result, ['Foo::Bar'], "->extract_via_statement() is correct (list context)" );
  }


  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    is( $result, undef, "->extract_via_comment() is undef" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    is_deeply( \@result, [undef], "->extract_via_comment() is undef (list context)" );
  }
};

subtest 'Make sure heredocs aren\'t parsed' => sub {

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
};

subtest 'Override tests' => sub {

  my $sample = <<'EOF';
package Foo::Bar;

# PODNAME: Override

1;
EOF

  {
    my $result = _Document( \$sample );
    isa_ok( $result, 'PPI::Document', '_Document(\\$sample)' );
  };

  {
    my $result = PPIx::DocumentName->extract( \$sample );
    is( $result, 'Override', "->extract() gets comment override" );
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    is_deeply( \@result, ['Override'], "->extract() gets comment override (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    is( $result, 'Foo::Bar', "->extract_via_statement() gets package statement" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    is_deeply( \@result, ['Foo::Bar'], "->extract_via_statement() gets package statement (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    is( $result, 'Override', "->extract_via_comment() gets PODNAME" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    is_deeply( \@result, ['Override'], "->extract_via_comment() gets PODNAME (list context)" );
  }
};

subtest 'Empty test' => sub {

  my $sample = '';

  {
    my $result = PPIx::DocumentName->extract( \$sample );
    is( $result, undef, "->extract()" );
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    is_deeply( \@result, [undef], "->extract() (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    is( $result, undef, "->extract_via_statement()" );
  }

  {
    # old api is inconsistent
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    is_deeply( \@result, [], "->extract_via_statement() (list context)" );
  }

  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    is( $result, undef, "->extract_via_comment()" );
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    is_deeply( \@result, [undef], "->extract_via_comment() (list context)" );
  }
};

done_testing;
