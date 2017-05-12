use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception);

sub no_fatals {
  my ( $reason, $code ) = @_;
  my $e = exception { $code->() };
  if ( not $e ) {
    return pass("<NO FATALS>:$reason");
  }
  diag($e);
  return fail("<EXPECTED NO FATALS>:$reason");
}

sub fatals {
  my ( $reason, $code ) = @_;
  my $e = exception { $code->() };
  if ( not $e ) {
    return fail("<FATALS EXPECTED>:$reason");
  }
  pass("<EXPECTED FATALS>:$reason");
  return $e;
}

sub call_value_is {
  my ( $object, $method, $args, $value, $reason ) = @_;
  $reason ||= "instance->$method(...) is $value";
  @_ = ( $object->$method(@$args), $value, $reason );
  goto \&is;
}

sub call_value_is_ref {
  my ( $object, $method, $args, $value, $reason ) = @_;
  $reason ||= "ref instance->$method(...) is $value";
  @_ = ( ref $object->$method(@$args), $value, $reason );
  goto \&is;
}

sub call_value_is_deep {
  my ( $object, $method, $args, $value, $reason ) = @_;
  $reason ||= "instance->$method(...) is deeply $value";
  @_ = ( $object->$method(@$args), $value, $reason );
  goto \&is_deeply;
}

sub call_value_ok {
  my ( $object, $method, $args, $reason ) = @_;
  $reason ||= "instance->$method(...) is ok";
  @_ = ( $object->$method(@$args), $reason );
  goto \&ok;
}

sub call_value_not_ok {
  my ( $object, $method, $args, $reason ) = @_;
  $reason ||= "instance->$method(...) is not ok";
  @_ = ( !$object->$method(@$args), $reason );
  goto \&ok;
}

BEGIN {
  delete $ENV{PACKAGE_DEBUG_ALL};
  delete $ENV{PACKAGE_DEBUG_LOG_PREFIX_STYLE};
  delete $ENV{FOO_DEBUG};
}
{

  package Foo;
  use Package::Debug::Object;

  my $instance;

  sub i_instance {
    return $instance if defined $instance;
    my $instance = Package::Debug::Object->new();
    $instance->auto_set_into(0);
    $instance->inject_debug_value();
    $instance->inject_debug_sub();
    return $instance;
  }
}

my $i;
no_fatals "get the instance" => sub {
  $i = Foo->i_instance;
};
no_fatals "trying to change DEBUG variable" => sub {
  no warnings 'once';
  $Foo::DEBUG = 2;
};

no_fatals "safe methods" => sub {
  call_value_is( $i, 'debug_style',                   [], 'prefixed_lines' );
  call_value_is( $i, 'env_key',                       [], 'FOO_DEBUG' );
  call_value_is( $i, 'env_key_from_package',          [], 'FOO_DEBUG' );
  call_value_is( $i, 'env_key_prefix',                [], 'FOO' );
  call_value_is( $i, 'env_key_prefix_from_package',   [], 'FOO' );
  call_value_is( $i, 'env_key_prefix_style',          [], 'default' );
  call_value_is( $i, 'env_key_style',                 [], 'default' );
  call_value_is( $i, 'into',                          [], 'Foo' );
  call_value_is( $i, 'into_level',                    [], '0' );
  call_value_is( $i, 'log_prefix',                    [], 'Foo' );
  call_value_is( $i, 'log_prefix_from_package_long',  [], 'Foo' );
  call_value_is( $i, 'log_prefix_from_package_short', [], 'Foo' );
  call_value_is( $i, 'log_prefix_style',              [], 'short' );
  call_value_is( $i, 'sub_name',                      [], 'DEBUG' );
  call_value_is( $i, 'value_name',                    [], 'DEBUG' );
  call_value_is_deep( $i, 'env_key_aliases', [ [] ], [] );
  call_value_is_ref( $i, 'debug_prefixed_lines', [], 'CODE' );
  call_value_is_ref( $i, 'debug_sub',            [], 'CODE' );
  call_value_is_ref( $i, 'debug_verbatim',       [], 'CODE' );
  call_value_not_ok( $i, 'is_env_debugging', [] );

};

done_testing;
