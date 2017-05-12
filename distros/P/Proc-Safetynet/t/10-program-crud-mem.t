use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;

BEGIN {
    use_ok 'Proc::Safetynet';
    use_ok 'Proc::Safetynet::Program::Storage::Memory';
}

my $storage = Proc::Safetynet::Program::Storage::Memory->new( );

my ($o, $x);
my $list;

# retrieve all (empty)


$list = $storage->retrieve_all();
is_deeply $list, [ ];

$o = Proc::Safetynet::Program->new( name => 'perl', command => $^X );
ok defined $o;
isa_ok $o, 'Proc::Safetynet::Program';
is $o->name, 'perl';
is $o->command, $^X;

# retrieve all
$list = $storage->retrieve_all();
is_deeply $list, [ ];

# add
ok $storage->add( $o );
dies_ok {
    ok $storage->add( $o );
} 'duplicate';

$list = $storage->retrieve_all();
is_deeply $list, [ Proc::Safetynet::Program->new( name => 'perl', command => $^X ) ];

$o = $storage->retrieve( 'non-existent-name' );
ok not defined $o;

$o = $storage->retrieve( 'perl' );
ok defined $o;
isa_ok $o, 'Proc::Safetynet::Program';
is $o->name, 'perl';
is $o->command, $^X;


# remove
$x = $storage->remove( undef );
is $x, undef;

$list = $storage->retrieve_all(); # check nothing was deleted
is_deeply $list, [ Proc::Safetynet::Program->new( name => 'perl', command => $^X ) ];

$x = $storage->remove( 'non-existent-name-here' );
is $x, undef;

$list = $storage->retrieve_all(); # check nothing was deleted
is_deeply $list, [ Proc::Safetynet::Program->new( name => 'perl', command => $^X ) ];

$x = $storage->remove( 'perl' );
$list = $storage->retrieve_all();
is_deeply $list, [ ], 'remove success';

# add more
{
    $storage->add( Proc::Safetynet::Program->new( name => 'echo', command => '/bin/echo' ) );
    $storage->add( Proc::Safetynet::Program->new( name => 'cat', command => '/bin/cat' ) );

    $list = $storage->retrieve_all();
    is_deeply $list, [ 
        Proc::Safetynet::Program->new( name => 'cat', command => '/bin/cat' ),
        Proc::Safetynet::Program->new( name => 'echo', command => '/bin/echo' ),
    ];
}



lives_ok {
    $storage->commit();
} 'committed';


lives_ok {
    $storage->reload();
} 'reloaded';

# add errors
lives_ok {
    $storage->add( Proc::Safetynet::Program->new( name => 'valid', command => '/bin/cat' ) );
} 'add-stress-valid1';
lives_ok {
    $storage->add( Proc::Safetynet::Program->new( name => 'valid-2', command => '/bin/cat' ) );
} 'add-stress-valid2';
lives_ok {
    $storage->add( Proc::Safetynet::Program->new( name => 'valid_3', command => '/bin/cat' ) );
} 'add-stress-valid3';
lives_ok {
    $storage->add( Proc::Safetynet::Program->new( name => '4valid_3', command => '/bin/cat' ) );
} 'add-stress-valid4';
dies_ok {
    $storage->add( Proc::Safetynet::Program->new( name => 'in-valid+', command => '/bin/cat' ) );
} 'add-stress-invalid1';
dies_ok {
    $storage->add( Proc::Safetynet::Program->new( name => 'in=valid', command => '/bin/cat' ) );
} 'add-stress-invalid2';
dies_ok {
    $storage->add( Proc::Safetynet::Program->new( name => 'in=valid`~!@#$%^&*()+=[]{}|\\/<>,.', command => '/bin/cat' ) );
} 'add-stress-invalid3';



__END__
