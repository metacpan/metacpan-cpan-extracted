use Project::Libs;
use t::Utils;
use Test::More;
use Text::TestBase::SubTest;

{
    my $hunk = <<'...';
=== hogehoge
--- input
xxx
--- expected
yyy

=== XXX
...
    my $root = Text::TestBase::SubTest->new->parse($hunk);
    subtest 'block1' => sub {
        my $block = $root->child_blocks(0);
        is($block->name, 'hogehoge');
        is($block->get_lineno, 1);
    };
    subtest 'block2' => sub {
        my $block = $root->child_blocks(1);
        is($block->name, 'XXX');
        is($block->get_lineno, 7);
    };
}

{
    my $hunk = <<'...';
=== hogehoge
--- ONLY
--- input
xxx
--- expected
yyy
...
    my $block = Text::TestBase::SubTest->new()->_make_block($hunk);
    subtest 'check' => sub {
        is($block->get_section('input'), "xxx\n");
        is($block->input, "xxx\n");
        is($block->get_section('expected'), "yyy\n");
        is($block->description, "hogehoge");
        is($block->name, "hogehoge");
        ok($block->has_section('ONLY'));
        ok(not $block->has_section('SKIP'));
    };
}

done_testing;
