use strict;
use warnings;
use Test::More tests => 25;
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok 'Proc::Safetynet';
    use_ok 'Proc::Safetynet::Program::Storage::TextFile';
}

my $storage_file = "$$.programs";


my $storage = Proc::Safetynet::Program::Storage::TextFile->new(
    file => $storage_file,
);

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

{
    $list = $storage->retrieve_all();
    is_deeply $list, [ 
        Proc::Safetynet::Program->new( name => 'cat', command => '/bin/cat' ),
        Proc::Safetynet::Program->new( name => 'echo', command => '/bin/echo' ),
    ];
}

lives_ok {
    $storage->reload();
} 'reloaded';
diag Dumper( $storage->retrieve_all() );


END {
    if (-e $storage_file) {
        eval {
            unlink $storage_file;
        };
        if ($@) {
            fail "storage_file cannot be deleted";
        }
    }
}

__END__
