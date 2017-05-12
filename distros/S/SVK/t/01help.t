#!/usr/bin/perl -w
use Test::More;
use strict;
use SVK::Test;

plan skip_all => 'MANIFEST not exists' unless -e 'MANIFEST';
open FH, 'MANIFEST' or die $!;
my @cmd = map { chomp; s|^lib/SVK/Command/(\w+)\.pm$|$1| ? $_ : () } <FH>;
my $pager = $ENV{SVKPAGER};
delete $ENV{SVKPAGER};
our $output;
my ($xd, $svk) = build_test();

plan tests => ( 9 + ( 2 * @cmd ) );

is_output_like ($svk, 'help', [], qr'Main index');
is_output_like ($svk, 'help', ['commands'], qr'Available commands:');
is_output ($svk, 'nosuchcommand', [], ["Command not recognized, try $0 help."]);
is_output ($svk, 'bad:command/', [], ["Command not recognized, try $0 help."]);
is_output ($svk, 'help', ['bzzzzz'], ["Cannot find help topic 'bzzzzz'."]);

{
    my $warned = 0;
    is_output ($svk, 'help', ['--boo'], ['Unknown option: boo']);
}

for (@cmd) {
    s|^.*/(\w+)\.pm|$1|g;
    is_output_like ($svk, 'help', [lc($_)], qr'SYNOPSIS');
    is_output_like ($svk, lc($_), ['--help'], qr'SYNOPSIS');
}

# Test ALIASES section
{
    # First with rm which has aliases.
    is_output_like ($svk, 'help', ['delete'], qr/\nALIASES\n\n\s+del, remove, rm\n/);

    # Then with add which has no aliases.
    $svk->help('add');
    like( $output, qr/\nSYNOPSIS\n\n/ );
    unlike( $output, qr/\nALIASES\n\n/ );
}
