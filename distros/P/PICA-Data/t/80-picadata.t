use strict;
use Test::More;
use App::picadata;

my $app;

my %default = (command => 'convert', number => 0, color => '', input => ['-'], path => []);

sub test_args {
    my ($args, $opts, $test) = @_;

    my $app = App::picadata->new(@$args);
    is_deeply $app, {%default, %$opts}, $test || join ' ', @$args;
}

# test_args( [], { command => 'help' }, 'default arguments' );
test_args( [qw(-3 foo.xml)], { number => 3, input => ['foo.xml'], to => 'XML' }, 'parse arguments');

test_args( [qw(003@ 123A|012X -p 200X)],
    { path => [qw(200X 003@ 123A 012X)], to => 'Plain' }, 'multiple path expressions');
test_args( [qw(003@$0 123A$x)],
    { path => [qw(003@$0 123A$x)], command => 'get' }, 'get subfield values');

# command options for backwards compatibility
test_args( [qw(-V)], { command => 'version' });
test_args( [qw(-c)], { command => 'count' });
test_args( [qw(-b)], { command => 'build' });

done_testing;
