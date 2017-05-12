
use strict;
no strict 'refs';

use Test;
use Term::ANSIColorx::ColorNicknames;

my %todo = (
    colored_1 => [  [["bold","blue"],"this","that"] => [['sky'],'this','that']       ],
    colored_2 => [  ["this that", "bold", "blue"]   => ["this that", "sky"]          ],
    colored_3 => [  ["this that", "carina round"]   => ["this that", "carina round"] ],
    # Carina Round isn't a color … :/

    color_1 => [ ['blue'],               ['blue'] ],
    color_2 => [ ['bold blue'],          ['sky'] ],
    color_3 => [ ['bold blue on_white'], ['bold-sky-on-white'] ],
    color_4 => [ ['bold yellow'],        ['bold yellow'] ],
    color_5 => [ ['yellow'],             ['normal yellow'] ],

    # … from the perlpod — is this really true?
    # "bold blue" eq fix_color("bold dark bold faint dark bold blue");
    # "blue"      eq fix_color("dark bold bold faint dark bold blue");
    color_6 => [ ["bold blue"], ["bold dark bold faint dark bold blue"] ],
    color_7 => [ ["dark blue"], ["dark bold bold faint dark bold blue"] ],
    color_8 => [ ["blue"],      ["normal bold bold bold bright blue"] ],

    # Wait, MJK isn't a color either.  Donkey Punch the Night Away.
    color_9 => [ ['maynard james keenan'], ['maynard james keenan'] ],

    color_10 => [ ["bold white on_blue"], ["mc-file"] ],
    color_11 => [ ["bold green on_blue"], ["nc_exe"] ],
    color_12 => [ ["black on_white"],     ["mc-pwd"] ],

    uncolor    => [ ["\e[1;34m"], ["\e[1;34m"] ],
    colorstrip => [ ["\e[1;34m"], ["\e[1;34m"] ],

    colorvalid => [ ["blue"], ["sky"] ],
);

plan tests => 2 * (keys %todo);

for my $key (sort keys %todo) {
    my $f = $key; $f =~ s/_\d+$//;

    my @r1 = eval { "Term::ANSIColorx::ColorNicknames::$f"->(@{ $todo{$key}[1] }) };
    my $e1 = $@; my $e1l = $1 if $e1 =~ m/line (\d+)/;

    my @r2 = eval { "Term::ANSIColor::$f"->(@{ $todo{$key}[0] }) };
    my $e2 = $@; $e2 =~ s/line \d+/line $e1l/ if $e1l;

    ok( "@r1 -$key-" . (0+@r1), "@r2 -$key-" . (0+@r2) );
    ok( "$e1 -$key", "$e2 -$key" );
}
