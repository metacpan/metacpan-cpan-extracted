#!/usr/bin/env perl

use lib './t/lib';
use Template::Plugin::DataPrinter::TestUtils;

use Test::More;
require Test::NoWarnings;

use File::Temp      ();
use Term::ANSIColor qw< colorstrip >;

delete $ENV{DATAPRINTERRC}; # make sure user rc doesn't interfere

{
    note 'Testing rcfile usage';

    my $hashsep = '{FINDME}';

    my $rcfile = File::Temp->new;
    print {$rcfile} "{
        hash_separator => '$hashsep',
        colored => 0,
    };";
    $rcfile->flush;

    my $filename = $rcfile->filename;

    my $template = "[%
        USE DataPrinter( dp = { rc_file = '$filename' } );
        hash = { a = 1, b = 2 };
        DataPrinter.dump(hash);
    %]";

    my $ansi = process_ok($template, {}, 'rc_file template processed ok');

    like($ansi, qr/$hashsep/, 'output contains expected hashsep');

    TODO: {
        local $TODO = 'colored = 0 flag in rc_file gets overridden';
        is($ansi, colorstrip($ansi), 'colored = 0 flag works');
    };
}

Test::NoWarnings::had_no_warnings();
done_testing;
