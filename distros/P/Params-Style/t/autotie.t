#!/usr/bin/perl -w
use strict; 

use Test::More tests => 18;

use Params::Style qw( :all);
ok( 1, "loading module");


is(  ps( foo_bar => 'fooBar', totoTata => 'titiTutu'),
    "ps( foo_bar => 'fooBar', toto_tata => 'titiTutu')",
    "perl_style with regular hash"
  );

is(  ps3( foo_bar => 'fooBar', totoTata => 'titiTutu'),
    "ps3( foo_bar => 'fooBar', toto_tata => 'titiTutu')",
    "default style with regular hash"
  );

is(  js( foo_bar => 'fooBar', totoTata => 'titiTutu'),
    "js( fooBar => 'fooBar', totoTata => 'titiTutu')",
    "javaStyle with regular hash"
  );

is(  js2( foo_bar => 'fooBar', totoTata => 'titiTutu'),
    "js2( FooBar => 'fooBar', TotoTata => 'titiTutu')",
    "JavaStyle with regular hash"
  );

is(  ps2( { foo_bar => 'fooBar', totoTata => 'titiTutu'}),
    "ps2( { foo_bar => 'fooBar', toto_tata => 'titiTutu' })",
    "perl_style with hashref"
  );

is( ns( foo_bar => 'fooBar', totoTata => 'titiTutu'),
    "ns( foobar => 'fooBar', tototata => 'titiTutu')",
    "no style with hash"
  );

is( ns2( { foo_bar => 'fooBar', totoTata => 'titiTutu'}),
    "ns2( { foobar => 'fooBar', tototata => 'titiTutu' })",
    "no style with hashref"
  );

is( codestyle( { fooXML => "toto", fooXMLBar => "tata", fooXMLABar => "titi" }),
    "codestyle( { foo_XML => 'toto', foo_XML_bar => 'tata', foo_xmla_bar => 'titi' })",
    "code ref passed",
  );

my @to_test= ( fooBar => "toto", TooBAR => "tata");
my %to_test= @to_test;
my $expected= "foo_bar => 'toto', too_BAR => 'tata'";

is( rk( @to_test), $expected, "replace_keys with array");
is( rk( %to_test), $expected, "replace_keys with hash");
is( rk( \@to_test), $expected, "replace_keys with array");
is( rk( \%to_test), $expected, "replace_keys with hashref");

eval { replace_keys( \&Params::Style::perl_style, \&rk) };
ok( $@=~ m{^wrong arguments type}, "wrong argument type (sub)");
eval { replace_keys( \&Params::Style::perl_style, 'foo') };
ok( $@=~ m{^wrong arguments type}, "wrong argument type (scalar)");

eval { replace_keys( \&Params::Style::perl_style, 'foo', 'bar', 'baz') };
ok( $@=~ m{^odd number of arguments passed}, "odd number of arguments passed (array): $@");
eval { replace_keys( \&Params::Style::perl_style, ['foo']) };
ok( $@=~ m{^odd number of arguments passed}, "odd number of arguments passed (array ref): $@");

eval { my %h : ParamsStyle( 'foo'); };
ok( $@=~ m{^wrong Params::Style style 'foo'}, "wrong style: $@");

sub rk
  { 
    params_string( replace_keys( \&Params::Style::perl_style, @_)); 
  }

sub ps
    { my %params : ParamsStyle( 'perl_style')= @_;
      return "ps( " . params_string( %params) . ")";
    }

sub ps2
    { my %params : ParamsStyle( 'perl_style');
      %params= %{shift()};
      return "ps2( { " . params_string( %params) . " })";
    }
    
sub ps3
    { my %params : ParamsStyle= @_;
      return "ps3( " . params_string( %params) . ")";
    }


sub js
    { my %params : ParamsStyle( 'javaStyle')= @_;
      return "js( " . params_string( %params) . ")";
    }

sub js2
    { my %params : ParamsStyle( 'JavaStyle')= @_;
      return "js2( " . params_string( %params) . ")";
    }


sub ns
    { my %params : ParamsStyle( 'nostyle')= @_;
      return "ns( " . params_string( %params) . ")";
    }

sub ns2
    { my %params : ParamsStyle( 'nostyle')= %{shift()};
      return "ns2( { " . params_string( %params) . " })";
    }
  
sub codestyle
  {  my %params : ParamsStyle( \&code)= %{shift()};
     return "codestyle( { " . params_string( %params) . " })";
  }
  
sub code
  { my( $string)= @_;
    my %uc= map { $_ => 1 } qw( XML);
    my @parts;
    while( $string=~ s{^_?([a-z]+|[A-Z][a-z]+|[A-Z]+)(?=[A-Z_]|$)}{}) { push @parts, $1; }
    @parts= map { $uc{uc()} ? uc : lc } @parts;
    return join( _ => @parts);
  }

sub params_string
  { my %params= ref( $_[0]) eq 'ARRAY' ? @{$_[0]}
              : ref( $_[0]) eq 'HASH'  ? %{$_[0]}
                                     : @_;
    return join( ", ", map { qq{$_ => '$params{$_}'} } sort keys %params);
  }


