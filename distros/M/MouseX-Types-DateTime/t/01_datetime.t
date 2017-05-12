use Test::Base;
use t::App;

plan tests => (3*2) * blocks;

filters { args => ['eval'] };

run {
    my $block = shift;
    my $args = $block->args || $block->input;

    for my $class (qw(Foo Bar)) {
        my $app = $class->new( datetime => $args );
        isa_ok $app => $class;
        isa_ok $app->datetime => 'DateTime';
        is     $app->datetime => $block->expected;
    }
};

__END__
=== Num
--- input: 1230768000
--- expected: 2009-01-01T00:00:00

=== Str
--- input: first day of 2009-01
--- expected: 2009-01-01T00:00:00

=== HashRef
--- args: { year => 2009, month => 1, day => 1, hour => 0, minute => 0, second => 0 }
--- expected: 2009-01-01T00:00:00
