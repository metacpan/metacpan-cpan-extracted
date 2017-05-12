
use strict;
#use warnings;

use English qw( -no_match_vars );
use Test::More;

if ( $OSNAME =~ /cygwin|win32|windows/i ) {
    plan skip_all => "doesn't work on windows";
}
else {
    plan 'no_plan';
};


use lib "lib";

use_ok('Provision::Unix');
require_ok('Provision::Unix');

# let the testing begin

# basic OO mechanism
my $prov = Provision::Unix->new( debug => 0 );
ok( defined $prov,                 'get Provision::Unix object' );
ok( $prov->isa('Provision::Unix'), 'check object class' );

# error message stack
push @{ $prov->{error} }, { errmsg => 'test error' };

#use Data::Dumper qw( Dumper ); warn Dumper ( $prov );

# show_version
ok( $prov->get_version(), 'get_version');

# find_config
ok( $prov->find_config( file => 'provision.conf', debug => 0, fatal => 0 ),
    'find_config valid' );
ok( !eval { $prov->find_config( fil => 'provision.conf', debug => 0, fatal => 0 ) },
    'find_config missing param' );
ok( !$prov->find_config( file => 'provisoin.conf', debug => 0, fatal => 0 ),
    'find_config invalid param' );

# error
ok( !$prov->error( 'test error', fatal => 0, debug => 0 ),
    'error' );

# error, missing argument
ok( !eval { $prov->error() }, 'error' );

# progress
ok( $prov->progress( num => 10, desc => 'test status' ), 'progress' );

if ( 0 == 1 ) {
    print "\n";
    sleep 1;
    $prov->progress( num => 1, desc => 'performing magic' );
    sleep 1;
    $prov->progress( num => 2, desc => 'slight of hand' );
    sleep 1;
    $prov->progress( num => 3, desc => 'hat trick' );
    sleep 1;
    $prov->progress( num => 4, desc => 'illusion' );
    sleep 1;
    $prov->progress( num => 10, desc => 'curtains closed' );

    print "error testing\n";
    $prov->progress( num => 1, desc => 'start' );
    sleep 1;
    $prov->progress( num => 2, desc => 'working hard' );
    sleep 1;
    $prov->progress( num => 3, desc => 'still working' );
    sleep 1;
    $prov->progress(
        num  => 4,
        desc => 'error',
        err  => 'oh no, a catastrophe!'
    );
}

# find_config
if ( $OSNAME !~ /cygwin|win32/ ) {
    ok( $prov->find_config(
            file  => 'services',
            debug => 0,
            fatal => 0,
        ),
        'find_config valid'
    );

# same as above but with etcdir defined
    ok( $prov->find_config(
            file   => 'services',
            etcdir => '/etc',
            debug  => 0,
            fatal  => 0
        ),
        'find_config valid'
    );
};

# this one fails because etcdir is set incorrect
ok( !$prov->find_config(
        file   => 'services',
        etcdir => '/ect',
        debug  => 0,
        fatal  => 0
    ),
    'find_config invalid dir'
);

# this one fails because the file does not exist
ok( !$prov->find_config(
        file  => 'country-bumpkins.conf',
        debug => 0,
        fatal => 0
    ),
    'find_config non-existent file'
);

