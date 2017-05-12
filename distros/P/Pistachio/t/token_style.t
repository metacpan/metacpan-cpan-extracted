use strict;
use warnings;

use Test::More;

BEGIN { 
    use_ok('Pistachio::Css::Github::Perl5', 'type_to_style');
    use_ok('Pistachio::Tokenizer');
    use_ok('Pistachio::Html');
}

my @tests = (
    ['my @count = $#my_list;', 6, 'ArrayIndex', 'color:#008080'],
    ['use constant FOO => 1;', 4, 'Word::Constant', 'color:#D14'],
    ['my @words = qw(a b c);', 6, 'QuoteLike::Words', 'color:#D14'],
    );

my $html = Pistachio::Html->new('Perl5', 'Github');
my $tokenizer = Pistachio::Tokenizer->new($html->lang);

TEST: for my $test (@tests) {
    my ($text, $expected_pos, $expected_type, $expected_style) = @$test;

    my $token_pos = 0;
    my $it = $tokenizer->iterator(\$text);

    while ($_ = $it->()) {
        my $msg = "TEST: "
                . "($expected_style, " . type_to_style($_->type) . ") "
                . "{$expected_type, ${\$_->type}}";
        $token_pos == $expected_pos && do {
            my $passed = $expected_type eq $_->type 
                      && $expected_style eq type_to_style $_->type;
            ok($passed, $msg);
            next TEST;
        };
        $token_pos++;
    }
}

done_testing;
