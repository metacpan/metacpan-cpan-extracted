use 5.10.1;
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

my $begin_errormessage = qr/^choose:/;

my $int = {
    beep         => '[ 0 1 ]',
    clear_screen => '[ 0 1 ]',
    hide_cursor  => '[ 0 1 ]',
    index        => '[ 0 1 ]',
    alignment    => '[ 0 1 2 ]',
    layout       => '[ 0 1 2 3 ]',
    mouse        => '[ 0 1 2 3 4 ]',
    order        => '[ 0 1 ]',
    page         => '[ 0 1 2 ]',
    keep         => '[ 1-9 ][ 0-9 ]*',
    ll           => '[ 1-9 ][ 0-9 ]*',
    max_height   => '[ 1-9 ][ 0-9 ]*',
    max_width    => '[ 1-9 ][ 0-9 ]*',
    default      => '[ 0-9 ]+',
    pad          => '[ 0-9 ]+',
};


my @wrong = ( -1, 2, 2 .. 10, 999999, '01', '', 'a', { 1, 1 }, [ 1 ], {}, [], [ 2 ] );


for my $opt ( sort keys %$int ) {
    for my $val ( grep { ! /^$int->{$opt}\z/x } @wrong ) {
        my $exception = exception { $d = choose( $choices, { $opt => $val } ) };
        ok( $exception =~ $begin_errormessage );
    }
}


my $string = {
    empty  => '',
    prompt => '',
    undef  => '',
};

my @wrong_string = ( { 1, 1 }, [ 1 ], {}, [], [ 2 ] );

for my $opt ( sort keys %$string ) {
    for my $val ( grep { ref } @wrong_string ) {
        my $exception = exception { $d = choose( $choices, { $opt => $val } ) };
        ok( $exception =~ $begin_errormessage );
    }
}


my $tabs_prompt = {
    tabs_prompt => 'Array_Int',
};
my @val_tabs_prompt = ( -2, -1, 0, 1, '', 'a', { 1, 1 }, {}  );

for my $opt ( sort keys %$tabs_prompt ) {
    for my $val ( @val_tabs_prompt ) {
        my $exception = exception { $d = choose( $choices, { $opt => $val } ) };
        ok( $exception =~ $begin_errormessage );
    }
}


my $no_spacebar = {
    no_spacebar => 'Array_Int',
};
my @val_no_spacebar = ( -2, -1, 0, 1, '', 'a', { 1, 1 }, {}  );

for my $opt ( sort keys %$no_spacebar ) {
    for my $val ( @val_no_spacebar ) {
        my $exception = exception { $d = choose( $choices, { $opt => $val } ) };
        ok( $exception =~ $begin_errormessage );
    }
}


my $exception = exception { $d = choose( $choices, {
    beep  => -1, clear_screen => 2, hide_cursor => 3, index => 4, alignment => '@', layout => 5, mouse => {}, order => 1,
    page => 3, keep => -1, ll => -1, max_height => 0, max_width => 0, default => [], pad => 'a', empty => [],
    prompt => {}, undef => [], tabs_prompt => 4, no_spacebar => 4 } ) };
ok( $exception =~ $begin_errormessage );

$exception = exception { $d = choose( [ 'aaa' .. 'zzz' ], {
    no_spacebar => 'a', tabs_prompt => 'b', undef => [], prompt => {}, empty => {}, pad => 'd', default => 'e', max_width => -1,
    max_height => -2, ll => -4, keep => -5, page => -6, order => -7, mouse => 'k', layout => 'e', alignment => [],
    index => {}, hide_cursor => -1,  clear_screen => [], beep  => 10 } ) };
ok( $exception =~ $begin_errormessage );


done_testing();

__DATA__
