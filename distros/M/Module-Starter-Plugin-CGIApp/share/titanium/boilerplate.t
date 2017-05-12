#!/usr/bin/perl

# Some tests to make sure you are not using default placeholders from the
# templates.  Remove this file after you have customized the distribution.
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 4 + <tmpl_var nummodules>;

sub not_in_file_ok {
    my ( $filename, %regex ) = @_;
    open my $fh, '<', $filename
        or die "couldn't open $filename for reading: $ERRNO";

    my %violated;

    while ( my $line = <$fh> ) {
        while ( my ( $desc, $regex ) = each %regex ) {
            if ( $line =~ $regex ) {
                push @{ $violated{$desc} ||= [] }, $NR;
            }
        }
    }
    close $fh or die "Close failed: $ERRNO";

    if (%violated) {
        fail("$filename contains boilerplate text");
        for ( keys %violated ) {
            diag "$_ appears on lines @{$violated{$_}}";
        }
    }
    else {
        pass("$filename contains no boilerplate text");
    }
    return;
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok(
        $module => 'the great new $MODULENAME' => qr/\Q - The great new \E/msx,
        'boilerplate description'  => qr/\QQuick summary of what the module\E/msx,
        'stub function definition' => qr/function[12]/msx,
    );
    return;
}

not_in_file_ok(
    '<tmpl_var buildscript>' => 'Abstract' => qr/\QAbstract goes here.\E/msx,
);

not_in_file_ok(
    LICENSE => 'License terms' => qr/\QInsert license text here.\E/msx,
);

not_in_file_ok(
    README => 'The README is used...' => qr/\QThe README is used\E/msx,
    "'version information here'" => qr/\Qto provide version information\E/msx,
);

not_in_file_ok( Changes => 'placeholder date/time' => qr{Date/time}msx );

<tmpl_loop module_pm_files>
module_boilerplate_ok('<tmpl_var module_pm_files_item>');
</tmpl_loop>

