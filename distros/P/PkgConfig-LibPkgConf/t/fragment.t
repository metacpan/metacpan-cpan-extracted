use strict;
use warnings;
use Test::More;
use PkgConfig::LibPkgConf::Fragment;

{
  package PkgConfig::LibPkgConf::Fragment;

  sub new
  {
    my($class, $type, $data) = @_;
    bless { type => $type, data => $data }, $class;
  }
}

subtest 'inc' => sub {

  my $example = PkgConfig::LibPkgConf::Fragment->new( 'I', '/foo/include' );

  is( $example->type, 'I' );
  is( $example->data, '/foo/include' );
  is( $example->to_string, '-I/foo/include' );
  is( "$example", "-I/foo/include" );

};

subtest 'lib' => sub {

  my $example = PkgConfig::LibPkgConf::Fragment->new( 'l', 'foo' );
  
  is( $example->type, 'l' );
  is( $example->data, 'foo' );
  is( $example->to_string, '-lfoo' );
  is( "$example", "-lfoo" );

};

subtest 'no type' => sub {

  my $example = PkgConfig::LibPkgConf::Fragment->new( undef, 'foo.c' );
  
  is( $example->type, undef );
  is( $example->data, 'foo.c' );
  is( $example->to_string, 'foo.c' );
  is( "$example", 'foo.c' );

};

done_testing;
