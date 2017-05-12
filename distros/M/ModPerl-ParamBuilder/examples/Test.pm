package Test; 

use Apache2::RequestRec;
use Apache2::RequestIO;

use Test::Params; 

sub handler { 
    my $r = shift; 

    my $params = Test::Params->new; 
    my $config = $params->get_config; 

    $r->content_type( 'text/plain' ); 

    foreach my $k ( keys( %{$config} ) ) { 

        if( ref( $$config{$k} ) eq 'ARRAY' ) { 
            $r->printf("%20s = %s\n", $k, join( ', ', @{$$config{$k}} ) );
        }
        else { 
            $r->printf("%20s = %s\n", $k, $$config{$k} );
        }
    }

    return( Apache2::Const::Ok );

}  # END handler 

1;
