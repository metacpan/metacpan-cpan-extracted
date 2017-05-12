use strict;
use warnings;
use Test::More;
BEGIN {
    eval q[use Test::Base;use t::TestPages; use YAML];
    plan skip_all => "Test::Base, Sledge::TestPage, YAML required for testing base" if $@;
};

delimiters('===', '***');

plan tests => 1 * blocks;

run {
    my $block = shift;

    {
        no strict 'refs'; 
        *{"t::TestPages::dispatch_test"} = $block->code;
    }

    my $page = t::TestPages->new;
    $page->dispatch('test');

    is($page->output, $block->expected, $block->name);
}

__END__

=== simple
*** code eval
sub {
    my ($self, ) = @_;

    $self->stash->{foo} = 'bar';
}
*** expected
---
stash:
  foo: bar
tmpl:
  foo: bar

