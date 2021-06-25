use 5.010000;
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Fatal;

use lib 'lib';
use Term::Choose qw( choose );


no warnings 'redefine';
sub Term::Choose::__get_key { sleep 0.01; return 0x0d };

close STDIN or plan skip_all => "Close STDIN $!";
my $stdin = "eingabe\n";
open STDIN, "<", \$stdin or plan skip_all => "STDIN $!";

close STDOUT or plan skip_all => "Close STDOUT $!";
close STDERR or plan skip_all => "Close STDERR $!";
my ( $tmp_stdout, $tmp_stderr );
open STDOUT, '>', \$tmp_stdout or plan skip_all => "STDOUT $!";
open STDERR, '>', \$tmp_stderr or plan skip_all => "STDERR $!";


my $choices = [ '', 0, undef, 1, 2, 3, 'aa' .. 'zz', '☻☮☺', "\x{263a}\x{263b}", '한글', 'æða' ];


my $d;

my $int = {
    beep                => [ 0, 1 ],
    clear_screen        => [ 0, 1 ],
    codepage_mapping    => [ 0, 1 ],
    hide_cursor         => [ 0, 1 ],
    index               => [ 0, 1 ],
    mouse               => [ 0, 1 ],
    order               => [ 0, 1 ],
    page                => [ 0, 1 ],
    alignment           => [ 0, 1, 2 ],
    color               => [ 0, 1, 2 ],
    f3                  => [ 0, 1, 2 ],
    include_highlighted => [ 0, 1, 2 ],
    layout              => [ 0, 1, 2, 3 ],
};

for my $opt ( sort keys %$int ) {
    for my $val ( @{$int->{$opt}}, undef ) {
        ok( ! defined( exception { $d = choose( $choices, { $opt => $val } ) } ) );
    }
}


my $one_or_greater = {
    keep       => '[ 1-9 ][ 0-9 ]*',
    ll         => '[ 1-9 ][ 0-9 ]*',
    max_cols   => '[ 1-9 ][ 0-9 ]*',
    max_height => '[ 1-9 ][ 0-9 ]*',
    max_width  => '[ 1-9 ][ 0-9 ]*',
};
my @val_one_or_greater = ( 1, 2, 100, 999999, undef );

for my $opt ( sort keys %$one_or_greater ) {
    for my $val ( @val_one_or_greater ) {
        ok( ! defined( exception { $d = choose( $choices, { $opt => $val } ) } ) );
    }
}


my $zero_or_greater = {
    default     => '[ 0-9 ]+',
    pad         => '[ 0-9 ]+',
};
my @val_zero_or_greater = ( 0, 1, 2, 100, 999999, undef );

for my $opt ( sort keys %$zero_or_greater ) {
    for my $val ( @val_zero_or_greater ) {
        ok( ! defined( exception { $d = choose( $choices, { $opt => $val } ) } ) );
    }
}


my $string = {
    empty       => '',
    footer      => '',
    info        => '',
    prompt      => '',
    undef       => '',
    busy_string => '',
};
my @val_string = ( 0, 'Hello' x 50, '', ' ', '☻☮☺', "\x{263a}\x{263b}", '한글', undef, 'æða' );
my $fail;
for my $opt ( sort keys %$string ) {
    for my $val ( @val_string ) {
        ok( ! defined( $fail = exception { $d = choose( $choices, { $opt => $val } ) } ), $fail // 'OK' );
    }
}


my $tabs = {
    tabs_info   => 'Array_Int',
    tabs_prompt => 'Array_Int',
};
my @val_tabs = ( [ 2, 4 ], [ 8 ], [], undef );

for my $opt ( sort keys %$tabs ) {
    for my $val ( @val_tabs ) {
        ok( ! defined( exception { $d = choose( $choices, { $opt => $val } ) } ) );
    }
}


my $list_opt = {
    mark        => 'Array_Int',
    meta_items  => 'Array_Int',
    no_spacebar => 'Array_Int',

};
my @val_list_opt = ( [ 0, 1, 2, 100, 999999 ], [ 1 ], undef );

for my $opt ( sort keys %$list_opt ) {
    for my $val ( @val_list_opt ) {
        ok( ! defined( exception { $d = choose( $choices, { $opt => $val } ) } ) );
    }
}


my $regex_opt = {
    skip_items => 'Regexp',
};
my @val_regex_opt = ( qr/^\s+\z/, qr/abc/ );

for my $opt ( sort keys %$regex_opt ) {
    for my $val ( @val_regex_opt ) {
        ok( ! defined( exception { $d = choose( $choices, { $opt => $val } ) } ) );
    }
}




ok( ! defined( exception {  $d = choose( $choices, {
    beep  => 0, clear_screen => undef, hide_cursor => 1, index => 0, alignment => 0, layout => 0, mouse => 0,
    order => 1, page => 0, keep => 1, ll => 1, max_height => 19, max_width => 19, default => 9, skip_items => qr/^\d+\z/,
    pad => 3, empty => '', prompt => '', undef => '', tabs_prompt => [ 1 ], no_spacebar => [ 0 ], info => 'hello' } ) } ) );

ok( ! defined( exception {  $d = choose( [ 'aaa' .. 'zzz' ], {
    no_spacebar => [ 11, 0, 8 ], tabs_prompt => [ 1, 1 ], undef => '', prompt => 'prompt_line', empty => '', pad => 3,
    default => 9, max_width => 19, max_height => 119, ll => 15, keep => 1, page => 1, order => 1, skip_items => qr/^\d+\z/,
    mouse => 0, layout => 3, alignment => 0, index => 0, hide_cursor => 1,  clear_screen => undef, beep  => 0 } ) } ) );


done_testing();

__DATA__
