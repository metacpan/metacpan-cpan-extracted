
package NetApp::Filer::License;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;

use Class::Std;
use Params::Validate qw( :all );

{

    my %service_of	:ATTR( get => 'service' );
    my %type_of		:ATTR( get => 'type' );
    my %code_of		:ATTR( get => 'code' );
    my %expired_of	:ATTR( get => 'expired' );
        
    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            service	=> { type	=> SCALAR },
            type	=> { type	=> SCALAR },
            code	=> { type	=> SCALAR },
            expired	=> { type	=> SCALAR },
        });

        $service_of{$ident}	= $args{service};
        $type_of{$ident}	= $args{type};
        $code_of{$ident}	= $args{code};
        $expired_of{$ident}	= $args{expired};

    }

}

1;
