#!perl
use strict;
use warnings;
use Capture::Tiny 'capture';
use File::Basename 'basename';
use OptArgs2::StatusLine 'RS', '$line', 'WARN';
use Test2::V0;

like dies { OptArgs2::StatusLine->import('junk') }, qr/expected/,
  'import exception';

my ( $basename, $RS, $prefix, $out, $err ) = ( basename($0) . ': ', RS );

# Initial condition and explicity undefined
is $line, undef, 'initially undefined';
( $out, $err ) = capture { $line = undef; };
is $out,  '',    'undef prints nothing';
is $err,  '',    'undef warns nothing';
is $line, undef, 'undef is undef';

# Default prefix based on program name
$prefix = $basename;
out_err_is( 'assignment', sub { $line = 'A'; },    "${prefix}A\n" );
out_err_is( 'empty',      sub { $line = ''; },     "${prefix}\n" );
out_err_is( 'newline',    sub { $line = "NL\n"; }, "${prefix}NL\n" );
out_err_is( 'newline was cleared', sub { $line .= 'X'; }, "${prefix}X\n" );
out_err_is( 'WARN', sub { $line = WARN . 'W'; },
    "${prefix}W\n", "${prefix}W\n" );
out_err_is( 'reassignment',  sub { $line = 'B'; },  "${prefix}B\n" );
out_err_is( 'concatenation', sub { $line .= 'C'; }, "${prefix}BC\n" );

# Prefix based on scalar reference
$prefix = '\$scalar: ';
out_err_is( 'prefix',     sub { $line = \$prefix; }, "${prefix}BC\n" );
out_err_is( 'assignment', sub { $line = 'A'; },      "${prefix}A\n" );
out_err_is( 'empty',      sub { $line = ''; },       "${prefix}\n" );
out_err_is( 'newline',    sub { $line = "NL\n"; },   "${prefix}NL\n" );
out_err_is( 'newline was cleared', sub { $line .= 'X'; }, "${prefix}X\n" );
out_err_is( 'WARN', sub { $line = WARN . 'W'; },
    "${prefix}W\n", "${prefix}W\n" );
out_err_is( 'reassignment',  sub { $line = 'B'; },  "${prefix}B\n" );
out_err_is( 'concatenation', sub { $line .= 'C'; }, "${prefix}BC\n" );

# Prefix based on ascii record separator
$prefix = 'RS: ';
out_err_is( 'RS prefix', sub { $line = $prefix . RS; },       "${prefix}BC\n" );
out_err_is( 'RS assign', sub { $line = $prefix . RS . '+'; }, "${prefix}+\n" );
out_err_is( 'assignment', sub { $line = 'A'; },               "${prefix}A\n" );
out_err_is( 'empty',      sub { $line = ''; },                "${prefix}\n" );
out_err_is( 'newline',    sub { $line = "NL\n"; },            "${prefix}NL\n" );
out_err_is( 'newline was cleared', sub { $line .= 'X'; }, "${prefix}X\n" );
out_err_is( 'WARN', sub { $line = WARN . 'W'; },
    "${prefix}W\n", "${prefix}W\n" );
out_err_is( 'reassignment',  sub { $line = 'B'; },  "${prefix}B\n" );
out_err_is( 'concatenation', sub { $line .= 'C'; }, "${prefix}BC\n" );

# Localization of status line
out_err_is(
    'local',
    sub {
        local $line;
        out_err_is( 'local default', sub { $line = 'X'; },   "${basename}X\n" );
        out_err_is( '\$scalar',      sub { $line = \'P:'; }, "P:X\n" );
        out_err_is( 'RS',   sub { $line = 'Q:' . RS; },       "Q:X\n" );
        out_err_is( 'RS2',  sub { $line = 'R:' . RS . 'S'; }, "R:S\n" );
        out_err_is( 'WARN', sub { $line = WARN . 'T'; }, "R:T\n", "R:T\n" );
    },
    "${prefix}BC\n"
);

out_err_is( 'concat old', sub { $line .= 'D'; }, "${prefix}BCD\n" );

done_testing();

sub out_err_is {
    my ( $name, $sub, $stdout, $stderr ) = @_;
    my ( $out, $err, $exit ) = capture { $sub->() };
    is $out, $stdout // '', $name . ': stdout ' . ( $stdout // '' ) =~ s/\n//r;
    is $err, $stderr // '', $name . ': stderr ' . ( $stderr // '' ) =~ s/\n//r;
}

