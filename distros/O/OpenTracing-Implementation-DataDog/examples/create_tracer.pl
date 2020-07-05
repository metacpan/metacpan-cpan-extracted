use strict;
use warnings;


use lib qw(lib ../lib);

use MyTracer;
use OpenTracing::GlobalTracer qw/$T/;

sub sleep_rand { sleep rand shift }

my $span_context = $T->extract_context;

my $scope = $T->start_active_span( "main", child_of => $span_context );

do {
    my $scope = $T->start_active_span( "Foo" );
#    my $scope = $T->start_active_span( "Foo" , child_of => $span_context );
    sleep_rand 3;
    
    do {
        my $scope1 = $T->start_active_span( "Bar1"  );
        
        sleep_rand 3;
        
        $scope1->close();
    };
    
    sleep_rand 3;
    
    do {
        my $scope2 = $T->start_active_span( "Bar2"  );
        $scope2->get_span->set_baggage_item( extra => 'stuff');
        $scope2->get_span->set_tag( 'http.method' => 'GET' );
        
        sleep_rand 3;
        
        do {
            my $scope9 = $T->start_active_span( "Quux"  );
            $scope9->get_span->set_tag( 'db.instance' => "mysql.host");
            
            sleep_rand 3;
            
            $scope9->close();
        };
        
        $scope2->close();
    };
    
    sleep_rand 3;
    
    do {
        my $scope3 = $T->start_active_span( "Bar3"  );
        
        sleep_rand 4;
        
        $scope3->close();
    };
    
    sleep_rand 2;
    
    do {
        my $scope4 = $T->start_active_span( "Bar4"  );
        
        sleep_rand 4;
        
        $scope4->close();
    };
    
#   use DDP; p $scope;
#   use DDP; p $scope->get_span;
    
    sleep_rand 3;
    
    $scope->close();
    
    undef $scope;
};

sleep_rand 3;

$scope->close;

sleep 0;

__END__
