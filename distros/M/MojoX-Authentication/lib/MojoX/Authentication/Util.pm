package MojoX::Authentication::Util;
use v5.24;
use experimental qw< signatures >;

use Scalar::Util qw< blessed >;
use Exporter qw< import >;
use Module::Runtime qw< use_module >;

our @EXPORT_OK = qw<
   coercer_for
   decode_name
   encode_name
>;

sub coercer_for ($name, $class) {
   return sub ($x) {
      return ($x->can($name) // sub { $_[0] })->($x) if blessed($x);
      return $x->() if ref($x) eq 'CODE'; # factory sub
      return use_module($class)->new($x);
   }
}

sub encode_name ($name) {
   return $name =~ s{([%/])}{sprintf('%%%02x', ord($1))}regmxs;
}

sub decode_name ($name) {
   return $name =~ s{%(..)}{chr(hex($1))}regmxs;
}

1;
