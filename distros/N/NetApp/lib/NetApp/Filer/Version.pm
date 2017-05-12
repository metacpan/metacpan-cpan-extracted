
package NetApp::Filer::Version;

our $VERSION = '500.002';
$VERSION = eval $VERSION;  ##  no critic: StringyEval

use strict;
use warnings;
use Carp;

use Class::Std;
use Params::Validate qw( :all );
use Data::Dumper;

use overload '""' => 'get_string';

{

    my %string_of	:ATTR( get => 'string' );

    my %release_of	:ATTR( get => 'release' );

    my %major_of	:ATTR( get => 'major' );
    my %minor_of	:ATTR( get => 'minor' );
    my %subminor_of	:ATTR( get => 'subminor' );
    my %patchlevel_of	:ATTR( get => 'patchlevel' );

    my %date_of		:ATTR( get => 'date' );

    sub BUILD {

        my ($self,$ident,$args_ref) = @_;

        my @args = %$args_ref;

        my (%args) 	= validate( @args, {
            string	=> { type	=> SCALAR },
        });

        $string_of{$ident}	= $args{string};

        $args{string} =~
            m{ NetApp \s+ Release \s+ (\S+) : \s+ (.*) }gmx ||
                   croak ("Invalid version string: $args{string}\n");

        $release_of{$ident}	= $1;
        $date_of{$ident}	= $2;

        ( $major_of{$ident}, 	$minor_of{$ident},
          $subminor_of{$ident},	$patchlevel_of{$ident} ) =
              split( /[\.L]+/, $release_of{$ident} );

    }

}

1;
