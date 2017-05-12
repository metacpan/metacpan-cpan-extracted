
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 2 + 5 + 5;
use strict;
use warnings;

# modules that we need
use Scalar::Util qw( reftype );
use String::Lookup;

# initializations
my $foo= 'foo';
my $bar= 'bar';
my %foobar= ( $foo => 1, $bar => 2 );

# set up the hash
my $ro_hash;
my $object= tie my %hash, 'String::Lookup',
  init => sub {
      return \%foobar;
  };

isa_ok( $object, 'String::Lookup', 'check object of tie' );
$ro_hash= %hash;
is( reftype($ro_hash), 'HASH', 'check fast access hash' );

# string 1
is( $hash{ \$foo },    1, 'simple string lookup' );
is( $ro_hash->{$foo},  1, 'fast same simple string lookup' );
is( $hash{ 1     }, $foo, 'simple id lookup' );
ok( exists $hash{ \$foo }, 'check existence of string' );
ok( exists $hash{ 1     }, 'check existence of id' );

# string 2
is( $hash{ \$bar },    2, 'another simple string lookup' );
is( $ro_hash->{$bar},  2, 'fast another same simple string lookup' );
is( $hash{ 2     }, $bar, 'another simple id lookup' );
ok( exists $hash{ \$bar }, 'check existence of another string' );
ok( exists $hash{ 2     }, 'check existence of another id' );
