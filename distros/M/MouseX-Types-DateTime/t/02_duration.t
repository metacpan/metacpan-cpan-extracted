use Test::Base;
use t::App;

plan tests => (3*2) * blocks;

filters { args => ['eval'] };

run {
    my $block = shift;
    my $args = $block->args || $block->input;

    for my $class (qw(Foo Bar)) {
        my $app = $class->new( duration => $args );
        isa_ok $app => $class;
        isa_ok $app->duration => 'DateTime::Duration';
        is $app->duration->seconds => $block->expected;
    }
};

__END__
=== Num
--- input: 60
--- expected: 60

=== Str
--- input: 1 minute
--- expected: 60

=== HashRef
--- args: { seconds => 60 }
--- expected: 60
