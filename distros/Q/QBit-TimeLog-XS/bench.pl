#!/usr/bin/perl

use qbit;

use FindBin qw($Bin);

use lib "$Bin/blib/lib";
use lib "$Bin/blib/arch";

use Benchmark qw(:all);

use QBit::TimeLog;
use QBit::TimeLog::XS;

cmpthese(
    -1,
    {
        'PP' => sub {
            my $timelog = QBit::TimeLog->new();

            $timelog->start('Main prog');

            $timelog->start('Action 1');
            $timelog->finish();

            $timelog->start('Action 2');
            $timelog->start('Action 3');
            $timelog->finish();
            $timelog->finish();

            $timelog->finish();
        },

        'XS' => sub {
            my $timelog = QBit::TimeLog::XS->new();

            $timelog->start('Main prog');

            $timelog->start('Action 1');
            $timelog->finish();

            $timelog->start('Action 2');
            $timelog->start('Action 3');
            $timelog->finish();
            $timelog->finish();

            $timelog->finish();
        },
    }
);
