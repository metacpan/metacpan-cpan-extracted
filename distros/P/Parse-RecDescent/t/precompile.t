use strict;
use warnings;
use Parse::RecDescent;
use Test::More tests => 14;
use lib '.';

# Turn off the "build a -standalone parser" precompile warning
our $RD_HINT = 0;

# mask "subroutine element redefined" warnings
local $^W;

my $grammar = <<'EOGRAMMAR';
TOP: <leftop: element /,/ element>(s?) ';' { $item[1] }
element: 'punctuation' {
    $thisparser->Extend('element: /!/');
    $return = $item[1];
}
| /\w+/
EOGRAMMAR


for my $standalone (0..1) {
    my $standalone_str = $standalone ? 'standalone' : 'dependent';
    my $class = "TestParser$standalone_str";
    my $pm_filename = $class . '.pm';

    if (-e $pm_filename) {
        unlink $pm_filename;
    }
    ok(!-e $pm_filename, "no preexisting precompiled parser");

    eval {
        Parse::RecDescent->Precompile({-standalone => $standalone,},
                                      $grammar,
                                      $class);
    };
    ok(!$@, qq{created a $standalone_str precompiled parser: } . $@);
    ok(-f $pm_filename, "found $standalone_str precompiled parser");

    eval "use $class;";
    ok(!$@, qq{use'd a $standalone_str precompiled parser: }.$@);

    unlink $pm_filename;
    ok(!-e $pm_filename, "deleted $standalone_str precompiled parser");

    my $result = eval qq{
    my \$text = "one, two, three, four,
punctuation, !, five, six, seven ;";

    use $class;
    my \$parser = $class->new();
    \$parser->TOP(\$text);
};
    ok(!$@, qq{ran a $standalone_str precompiled parser});
    is_deeply($result,
              [qw(one two three four punctuation
                  ! five six seven)],
              "correct result from precompiled parser");
}
