use Test::More;

use 5.20.0;

use experimental 'signatures';

use MoobX;

observable my $foo;

my @checks = ( sub { is $_[0] => undef, 'start with nothing' } );

my $o = autorun {
    my $check = shift @checks;
    $check->($foo) or diag explain $foo;
};

push @checks, sub { is_deeply $_[0], { foo =>  [ { bar => 'baz' } ] }, 'update a value' };

$foo = { foo => [ { bar => 'baz' } ] };

sub moob_test :prototype(&@) {
    my( $action, $test, $title ) = @_;
    push @checks, $test;
    subtest( $title || 'moob test', sub {
        $action->();
        done_testing();
    });
}

moob_test {
    $foo->{foo}[0]{bar} = 'bart';
} sub {
    is_deeply shift, { foo =>  [ { bar => 'bart' } ] };
}, 'update end value';

moob_test {
    $foo = [ 1, { foo => 'bar' } ];
} sub {
    is_deeply shift, [ 1, { foo =>  'bar' } ];
}, 'array -> hash';

moob_test {
    $foo->[1]{foo} = 'quux';
} sub {
    is_deeply shift, [ 1, { foo =>  'quux' } ];
}, 'array -> hash modification';


done_testing;
