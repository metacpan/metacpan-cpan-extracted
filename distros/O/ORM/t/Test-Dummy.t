#!/usr/bin/perl

use lib "t";
use Test::More tests => 20;

BEGIN
{
    use_ok( 'Test::Dummy' );
    use_ok( 'Test::Dummy::Child1' );
}

#ORM::DbLog->write_to_stdout( 1 );
#Test::Dummy->_cache->change_size( 0 );

my $error;
my $d1;
my $d2;

# TEST new
#
# simple new statement for primary class

$error = ORM::Error->new;
$d1    = Test::Dummy->new( prop=>{ a=>'a', b=>'b', c=>'c' }, error=>$error );

ok
(
    !$error->fatal && $d1 && $d1->a eq 'a' && $d1->b eq 'b' && $d1->c eq 'c',
    'new'
);

# TEST update
#
# simple update statement

$error = ORM::Error->new;
$d1->update( prop=>{ a=>'aa', b=>'bb' }, error=>$error );

ok
(
    !$error->fatal && $d1 && $d1->a eq 'aa' && $d1->b eq 'bb' && $d1->c eq 'c',
    'update'
);

# TEST update
#
# update with successfull test of current values

$error = ORM::Error->new;
$d1->update
(
    prop     => { b=>undef },
    old_prop => { a=>'aa', b=>'bb', c=>'c' },
    error    => $error,
);

ok
(
    !$error->fatal && $d1 && $d1->a eq 'aa' && ! defined $d1->b && $d1->c eq 'c',
    'update'
);

# TEST update
#
# update with faulty test of current values

$error = ORM::Error->new;
$d1->update
(
    prop     => { b=>'bbb' },
    old_prop => { a=>'aa', b=>'bb', c=>'c' },
    error    => $error
);

ok
(
    (
        $d1
        && $d1->a eq 'aa'
        && ! defined $d1->b
        && $d1->c eq 'c'
        && $error->text =~ / do not match properties assumed by user\n$/
    ),
    'update'
);

# TEST delete
#
# simple delete statement

$error = ORM::Error->new;
$d1->delete( error=>$error );

ok( !$error->fatal, 'delete' );

# TEST new
#
# new for non-primary class

$error = ORM::Error->new;
$d1 = Test::Dummy::Child1->new
(
    prop  => { a=>'a', b=>'b', c=>'c', ca=>'ca', cb=>'cb' },
    error => $error
);

ok
(
    !$error->fatal
    && $d1
    && $d1->a eq 'a' && $d1->b eq 'b' && $d1->c eq 'c'
    && $d1->ca eq 'ca' && $d1->cb eq 'cb',
    'new'
);

# TEST lazy_load
#
# non-lazy loading

$error = ORM::Error->new;
$d1 = Test::Dummy->find
(
    filter    => (Test::Dummy->M->id == $d1->id),
    error     => $error,
    lazy_load => 0,
);

ok
(
    !$error->fatal
    && ! exists $d1->{_ORM_missing_tables} 
    && ref $d1 eq 'Test::Dummy::Child1' 
    && $d1->{_ORM_data}{ca} eq 'ca',
    'lazy_load'
);

# TEST lazy_load
#
# not loaded second table

$d1->_cache->delete( $d1 );
$error = ORM::Error->new;
$d1 = Test::Dummy->find
(
    filter    => ( Test::Dummy->M->id == $d1->id ),
    error     => $error,
    lazy_load => 1
);

ok
(
    !$error->fatal && missing_tables_str( $d1 ) eq 'Dummy__Child1',
    'lazy_load',
);

# TEST lazy_load
#
# finish loading of lazy-loaded table

$d1->ca( error=>$error );

ok( !$error->fatal && ! exists $d1->{_ORM_missing_tables}, 'lazy_load' );

# TEST lazy_load
#
# non-lazy load with find_id

$d1->_cache->delete( $d1 );
$error = ORM::Error->new;
$d1    = Test::Dummy->find_id( id=>$d1->id, error=>$error );

ok
(
    !$error->fatal 
    && ! exists $d1->{_ORM_missing_tables} 
    && ref $d1 eq 'Test::Dummy::Child1' 
    && $d1->{_ORM_data}{ca} eq 'ca',
    'lazy_load'
);

# TEST lazy_load
#
# lazy load with find_id from base class

$d1->_cache->delete( $d1 );
$error = ORM::Error->new;
$d1 = Test::Dummy->find_id( id=>$d1->id, error=>$error, lazy_load=>1 );

ok
(
    !$error->fatal
    && missing_tables_str( $d1 ) eq 'Dummy' 
    && ref $d1 eq 'Test::Dummy',
    'lazy_load'
);

# TEST lazy_load
#
# first stage load after find_id

$d1->c( error=>$error );

ok
(
    missing_tables_str( $d1 ) eq 'Dummy__Child1'
    && ref $d1 eq 'Test::Dummy::Child1'
    && $d1->{_ORM_data}{c} eq 'c',
    'lazy_load'
);

# TEST lazy_load
#
# second stage load after find_id

$d1->ca( error=>$error );

ok
(
    ! exists $d1->{_ORM_missing_tables}
    && ref $d1 eq 'Test::Dummy::Child1'
    && $d1->{_ORM_data}{ca} eq 'ca',
    'lazy_load'
);

# TEST lazy_load
#
# lazy load with find_id from exact class

$d1->_cache->delete( $d1 );
$error = ORM::Error->new;
$d1 = Test::Dummy::Child1->find_id( id=>$d1->id, error=>$error, lazy_load=>1 );

ok
(
    !$error->fatal
    && missing_tables_str( $d1 ) eq 'Dummy,Dummy__Child1',
    'lazy_load'
);

# TEST update
#
# update of lazy loaded object

$error = ORM::Error->new;
$d1->update( prop=>{ a=>'aa', ca=>'cccaaa' }, error=>$error );

ok
(
    !$error->fatal && $d1 && $d1->a eq 'aa' && $d1->ca eq 'cccaaa',
    'update'
);

# TEST update
#
# update of non-primary class

$error = ORM::Error->new;
$d1->update( prop=>{ ca=>'ccaa' }, error=>$error );
ok( !$error->fatal && $d1 && $d1->ca eq 'ccaa', 'update' );

# TEST server_side_update

$error = ORM::Error->new;
$d1->update( prop=>{ ca=>($d1->M->ca)->_append( 'aa' ) }, error=>$error );

ok( !$error->fatal && $d1 && $d1->ca eq 'ccaaaa', 'server_side_update' );

# TEST delete

$error = ORM::Error->new;
$d1->delete( error=>$error );

ok( !$error->fatal, 'delete' );



# SUBROUTINES

sub missing_tables_str
{
    my $d1 = shift;
    
    join ',',
    (
        exists $d1->{_ORM_missing_tables}
        && sort keys %{$d1->{_ORM_missing_tables}}
    )
}
