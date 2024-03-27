#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    if( $] < 5.020000 )
    {
        plan skip_all => 
          "signatures tests unsupported for perl below v5.20";
    }
    # use Nice::Try debug_file => './dev/debug_t_024_signatures.pl', debug_code => 1, debug => 7, debug_dump => 1;
    use Nice::Try;
};

use strict;
use warnings;
use experimental 'signatures';
no warnings 'experimental';
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# Issue raised on Perl Monks <https://www.perlmonks.org/?node_id=11130251>
# Now solved with PPI 1.277
# <https://perldoc.perl.org/5.20.0/perldelta#Experimental-Subroutine-signatures>
# <https://perldoc.perl.org/5.20.0/perlsub#Signatures>

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

# <https://perldoc.perl.org/perlsub#Prototypes>
# <https://perldoc.perl.org/attributes#prototype(..)>
# <https://perldoc.perl.org/5.22.0/perldelta#Subroutine-signatures-moved-before-attributes>
# <https://perldoc.perl.org/5.28.0/perldelta#Subroutine-attribute-and-signature-order>
SKIP:
{
    my( $sig4name, $sig4err );
    
    my $proto_test;

    if( $] >= 5.022000 && $] <= 5.026003 )
    {
        # skip( "Skipping mixing prototype and signature for perl version between 5.22.0 and 5.26.3 as it was buggy.", 2 );
        $proto_test = <<'EOT';
sub callme3 ($name) :prototype($){
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
EOT
    }
    else
    {
        $proto_test = <<'EOT';
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
EOT
    }
    my $code = Nice::Try->implement( $proto_test );
    eval( $code );
    &callme3( 'Paul' );
    
    is( $sig4name, 'Paul', 'subroutine with prototype and signature value' );
    ok( defined( $sig4err ), 'subroutine with prototype and signature with 1 variable' );
}

done_testing();

__END__

