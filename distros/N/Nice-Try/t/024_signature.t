#!perl
use strict;
use warnings;
use lib './lib';
use Test::More qw( no_plan );
use Nice::Try;
use experimental 'signatures';
# Issue raised on Perl Monks <https://www.perlmonks.org/?node_id=11130251>
# Now solved with PPI 1.277

my $sig1err;

sub foo { 1 }
try {
  my $k = sub ($f = foo()) {die("Oops")};
  $k->();
}
catch ($e) {
  $sig1err = $e;
}

ok( defined( $sig1err ), 'anonymous subroutine with signature' );

my $sig2err;
sub callme () {
    try
    {
        die( 'Oops' );
    }
    catch( $e )
    {
        $sig2err = $e;
    }
}

&callme();

ok( defined( $sig2err ), 'subroutine with empty signature' );

my( $sig3name, $sig3err );
sub callme2 ($name)
{
    try
    {
        $sig3name = $name;
        die( 'Oops' );
    }
    catch( $e )
    {
        $sig3err = $e;
    }
}

&callme2( 'John' );

is( $sig3name, 'John', 'subroutine signature value' );
ok( defined( $sig3err ), 'subroutine with signature and 1 variable' );

my( $sig4name, $sig4err );

sub callme3 :prototype($) ($name){
    try
    {
        $sig4name = $name;
        die( 'Oops' );
    }
    catch( $e )
    {
        $sig4err = $e;
    }
}

&callme3( 'Paul' );

is( $sig4name, 'Paul', 'subroutine with prototype and signature value' );
ok( defined( $sig4err ), 'subroutine with prototype and signature with 1 variable' );

done_testing();

__END__

