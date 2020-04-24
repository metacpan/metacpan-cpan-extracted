use warnings;
use strict;

use Test::More;

if ($] >= 5.014 && $] < 5.016) {
    plan skip_all => 'Decommenting does not work under Perl 5.14';
    done_testing();
}
else {
    plan tests => 1;
}

use PPR;

my $text = <<'END_TEXT';

    my $x = 1;     # A comment
    my $y = 2;     # A comment
    my $z = q{ # The Z variable };   # A comment

    say $#;

    say ${'# Not a comment'};

!   =begin comment
!
!   A comment-like component here
!
!   =cut

    $x = $
    # A comment
    y [ # A comment
    # A comment
    0 # A comment
    ];

    say << 'FOO';
        # Ceci n'est pas un comment!
    FOO

    # A comment
    format STDERR =
    # Not a comment
    .

    say '#Here';

!   =begin comment
!
!   Another comment-like component here
!
END_TEXT

my $expected = $text;

$text     =~ s{^[! ]   }{}gm;

my $decommented = PPR::decomment($text);

$expected =~ s{^!.*}{}gm;
$expected =~ s{^    }{}gm;
$expected =~ s{# A comment\h*}{}g;

is $decommented, $expected => 'Decommented correctly';

done_testing();


