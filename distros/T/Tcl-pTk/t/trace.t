use Tcl::pTk;

use Test;
$| = 1;

plan tests => 5;

my $TOP = MainWindow->new();

my $perlscalar;
my $updateSubVar;

my $e1 = $TOP->Entry( -textvariable => \$perlscalar)->pack();

$TOP->traceVariable( \$perlscalar, 'wr' => \&update_sub );

# Testing of reading the perl variable (should trigger a read from Tcl)
$TOP->after(1000, sub{ $e1->insert("end", "new value")});

$TOP->after(2000, 
        sub{ 
                ok( $perlscalar,   "new value", "variable tie from tcl to perl");
                ok( $updateSubVar, "new value", "variable tie from tcl to perl");
        
        });


$TOP->after(3000, sub{ $perlscalar = "new value2"});

$TOP->after(4000, sub{ 
        ok( $e1->get,      "new value2", "variable tie from perl to tcl");
        ok( $updateSubVar, "new value2", "variable tie from perl to tcl");
});

# Cancel Tracing
$TOP->after(5000, sub{ 
        $TOP->traceVdelete(\$perlscalar);
        $e1->insert("end", "321");
        ok( $perlscalar,   "new value2321", "variable tie from tcl to perl after traceVdelete");
        $TOP->destroy;
});

MainLoop();

#print "perlscalar = $perlscalar\n";

#my $obj = tied $perlscalar;

#print "obj = $obj\n";


sub update_sub {
     my( $index, $value, $op, @args ) = @_;
     
     #print "Op = $op, update values = $value\n";
     $updateSubVar = $value;
     return $value;
}

