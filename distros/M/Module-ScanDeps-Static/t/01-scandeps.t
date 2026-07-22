use strict;
use warnings;

use lib qw{ . lib };

use Test::More;
use Data::Dumper;

plan tests => 3;

use_ok qw( Module::ScanDeps::Static );

our $CODE = <<'END_OF_CODE';
use Buz::Baz 1.0;
use Foo::Bar;

require Carp;
END_OF_CODE

########################################################################
subtest 'use' => sub {
########################################################################
  local @ARGV = ( '--add-version', 'scan' );

  no strict 'refs'; ## no critic
  no warnings 'redefine'; ## no critic

  *{'Module::ScanDeps::Static::cmd_scan'} = sub {
    my ($scanner) = @_;

    open my $fh, '<', \$CODE;
    $scanner->set_handle($fh);

    my @dependencies = $scanner->parse;
    my $require      = $scanner->get_require;

    ok( scalar @dependencies > 0, 'found dependencies' );
    isa_ok( $require, 'HASH', 'require is a HASH' );

    my $module_names = join q{}, @dependencies;

    is( $module_names, 'Buz::BazCarpFoo::Bar', 'sorted dependencies' );

    is( $dependencies[2], 'Foo::Bar', 'Foo::Bar' );

    ok( exists $require->{'Foo::Bar'}, 'version for Foo::Bar in hash' );

    is( $require->{'Foo::Bar'}, q{}, 'version is empty string' )
      or diag( Dumper( [ require => $require ] ) );

    is( $require->{'Buz::Baz'}, q{1.0}, 'version of Buz::Baz is 1.0' )
      or diag( Dumper \@dependencies );
  };

  Module::ScanDeps::Static->main();
};

########################################################################
subtest 'require' => sub {
########################################################################

  no strict 'refs'; ## no critic
  no warnings 'redefine'; ## no critic

  local @ARGV = qw(scan);

  *{'Module::ScanDeps::Static::cmd_scan'} = sub {
    my ($scanner) = @_;
    open my $fh, '<', \$CODE;

    $scanner->set_handle($fh);

    my @dependencies = $scanner->parse;
    my $require      = $scanner->get_require;

    ok( @dependencies, 'found 3 dependencies' )
      or diag( Dumper \@dependencies );

    ok( grep {/Carp/xsm} @dependencies, 'found require Carp' )
      or diag( Dumper \@dependencies );

    ok( defined $require->{'Carp'}, 'version defined' );
  };

  Module::ScanDeps::Static->main();
};

1;

