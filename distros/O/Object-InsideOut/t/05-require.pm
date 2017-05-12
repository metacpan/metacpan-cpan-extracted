use strict;
use warnings;

package t::AA; {
    use Object::InsideOut;

    my %aa : Field({'acc'=>'aa', 'type' => 'num'});

    my $id = 1;

    sub id : ID {
        return ($id++);
    }
}


package t::BB; {
    use Object::InsideOut;

    my %bb : Field( { 'get' => 'bb', 'Set' => 'set_bb' } );

    my %init_args : InitArgs = (
        'BB' => {
            'Field'     => \%bb,
            'Default'   => 'def',
            'Regex'     => qr/bb/i,
        },
    );
}


package t::AB; {
    use Object::InsideOut qw(t::AA t::BB);

    my %data : Field({'acc'=>'data'});
    my %info : Field('gET'=>'info_get', 'SET'=>'info_set');

    my %init_args : InitArgs = (
        'data' => {
            'Field' => \%data,
        },
        'info' => {
            'FIELD' => \%info,
            'DEF'   => ''
        },
    );
}

1;
