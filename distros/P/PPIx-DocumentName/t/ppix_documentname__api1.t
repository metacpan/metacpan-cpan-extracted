use strict;
use warnings;
use Test::More;
use PPIx::DocumentName -api => 1;
use PPI::Util qw( _Document );

sub check_package_node {
  my($name, @result) = @_;
  return ($name, sub {
    isa_ok $result[0], 'PPIx::DocumentName::Result';
    is "$result[0]", 'Foo::Bar';
    is $result[0]->name, 'Foo::Bar';
    isa_ok $result[0]->document, 'PPI::Document';
    isa_ok $result[0]->node, 'PPI::Statement::Package';
    is scalar(@result), 1;
  });
}

sub check_comment {
  my($name, @result) = @_;
  return ($name, sub {
    isa_ok $result[0], 'PPIx::DocumentName::Result';
    is "$result[0]", 'Override';
    is $result[0]->name, 'Override';
    isa_ok $result[0]->document, 'PPI::Document';
    isa_ok $result[0]->node, 'PPI::Token::Comment';
    is scalar(@result), 1;
  });
}

subtest 'basic' => sub {

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
    subtest check_package_node '->extract() is package statement', $result;
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    subtest check_package_node '->extract() is package statement (list context)', @result;
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    subtest check_package_node '->extract_via_statement() is correct', $result;
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    subtest check_package_node '->extract_via_statement() is correct (list context)', @result;
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
    subtest check_comment '->extract() gets comment override', $result;
  }

  {
    my @result = PPIx::DocumentName->extract( \$sample );
    subtest check_comment '->extract() gets comment override (list context)', @result;
  }

  {
    my $result = PPIx::DocumentName->extract_via_statement( \$sample );
    subtest check_package_node '->extract_via_statement() is correct', $result;
  }

  {
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    subtest check_package_node '->extract_via_statement() is correct (list context)', @result;
  }

  {
    my $result = PPIx::DocumentName->extract_via_comment( \$sample );
    subtest check_comment '->extract_via_comment() gets PODNAME', $result;
  }

  {
    my @result = PPIx::DocumentName->extract_via_comment( \$sample );
    subtest check_comment '->extract_via_comment() gets PODNAME (list context)', @result;
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
    my @result = PPIx::DocumentName->extract_via_statement( \$sample );
    is_deeply( \@result, [undef], "->extract_via_statement() (list context)" );
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
