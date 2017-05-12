use strict;
use warnings;
use Test::More;
use Moose 2.1604;
use Test::Moose 2.1604;
use Config;

my $class = 'Term::YAP::iThread';

BEGIN {

  SKIP: {

        skip 'ithreads is not available on this perl', 1
          unless ( $Config{useithreads} );

        use_ok('Term::YAP::iThread');

    }

}

SKIP: {

    skip 'ithreads is not available on this perl',3 
      unless ( $Config{useithreads} );

    has_attribute_ok( $class, 'queue' );
    has_attribute_ok( $class, 'detach' );
    can_ok( $class, qw(get_queue BUILD _no_detach _set_detach DEMOLISH) );

}

done_testing();
