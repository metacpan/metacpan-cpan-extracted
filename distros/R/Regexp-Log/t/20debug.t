use Test::More tests => 8;
use t::Foo;
use re 'eval';

my $foo = Regexp::Log::Foo->new();

# test the accessor
ok( ! $foo->debug, "No debug by default" );
$foo->debug(1);
ok( $foo->debug == 1 , "Debug set" );

@ARGV = ('t/foo1.log');
$foo->format("%a %b %c %d");

my @fields = $foo->capture;
my $regexp = $foo->regexp;

# swap errputs
my $file = "t/.test.$$";
open OLDERR, ">&STDERR"
      or die "fatal: could not duplicate STDERR: $!";
close STDERR;
open STDERR, "> $file"
      or die "fatal: could not open temporary errput file $file: $!"; 

# debug data should go to the file
while(<>) {
    my %data;
    @data{@fields} = /$regexp/;
}

# put things back to normal
close STDERR;
open STDERR, ">&OLDERR"
  or die "fatal: could not duplicate STDERR: $!";
close(OLDERR);

@ARGV = ($file);
is( <>, "\n",               "First line is empty" );
is( <>, "a b cs cn c d \n", "Debug for a match" );
is( <>, "a b cs cn c d \n", "Debug for a match" );
is( <>, "a b cs cn c d \n", "Debug for a match" );

# Perl 5.6 and Perl 5.8 backtrack differently!
if ( $] >= 5.008 ) {
    is( <>, "a \n", "Debug for non-match" );
}
else {
    is( <>, "a a \n", "Debug for non-match" );
}

is( <>, "a b cs cn c d ", "Debug for a match" );
close ARGV;

# cleanup files
unlink $file or diag "Could not remove $file: $!";
