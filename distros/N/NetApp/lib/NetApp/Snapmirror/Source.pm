
package NetApp::Snapmirror::Source;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;

use Class::Std;
use Params::Validate qw( :all );

{

    my %hostname_of	:ATTR( get => 'hostname' );
    my %volume_of	:ATTR( get => 'volume' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            hostname	=> { type	=> SCALAR },
            volume	=> { type	=> SCALAR },
        });

        $hostname_of{$ident}	= $args{hostname};
        $volume_of{$ident}	= $args{volume};

    }

}

1;
