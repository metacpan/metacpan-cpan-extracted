#! perl
use strict;
use warnings FATAL => qw(all);
use autodie;
use version; our $VERSION = qv('v0.0.5');

use Test::Approvals qw(verify use_reporter use_name namer);
use Test::Approvals::Specs qw(describe it run_tests);
use Test::More;
use Test::Approvals::Reporters;

use_reporter('Test::Approvals::Reporters::DiffReporter');

sub test_reporter {
    my $class    = shift;
    my $reporter = $class->new();
    my $cmd      = $reporter->exe . q{ } . $reporter->argv;

    my $ok = verify($cmd);
    if ( !$ok ) {
        $reporter->report( 'r.txt', 'a.txt' );
    }

    return $ok;
}

describe 'A CodeCompareReporter' => sub {
    it 'Reports with DevArt CodeCompare' => sub {
        use_name(shift);
        ok test_reporter 'Test::Approvals::Reporters::CodeCompareReporter',
          namer()->name();
    };
};

describe 'A WinMerge Reporter' => sub {
    it 'Reports with WinMerge' => sub {
        use_name(shift);
        ok test_reporter 'Test::Approvals::Reporters::WinMergeReporter',
          namer()->name();
    };
};

describe 'A File Launcher Reporter' => sub {
    it 'uses the shell to locate a reporter' => sub {
        use_name(shift);
        ok test_reporter 'Test::Approvals::Reporters::FileLauncherReporter',
          namer()->name();
    };
};

describe 'A BeyondCompare Reporter' => sub {
    it 'Reports with BeyondCompare' => sub {
        use_name(shift);
        my $class    = 'Test::Approvals::Reporters::BeyondCompareReporter';
        my $reporter = $class->new();
        my $cmd      = $reporter->exe . q{ } . $reporter->argv;

        my $programs = qr{C:\\Program\sFiles(?:\s[(]x86[)])?\\}mxs;
        my $program  = qr{Beyond\sCompare\s3\\BCompare.exe\s}mxs;

        my $ok = like $cmd,
          qr{$programs $program "RECEIVED"\s"APPROVED"}mxs,
          namer()->name;

        if ( !$ok ) {
            $reporter->report( 'r.txt', 'a.txt' );
        }

        return;
    };
};

describe 'A KDiff Reporter' => sub {
    it 'Reports with KDiff' => sub {
        use_name(shift);
        ok test_reporter 'Test::Approvals::Reporters::KDiffReporter',
          namer()->name();
    };
};

describe 'A P4Merge Reporter' => sub {
    it 'Reports with P4Merge' => sub {
        use_name(shift);
        ok test_reporter 'Test::Approvals::Reporters::P4MergeReporter',
          namer()->name();
    };
};

describe 'A TortoiseMerge Reporter' => sub {
    it 'Reports with TortoiseMerge' => sub {
        use_name(shift);
        ok test_reporter 'Test::Approvals::Reporters::TortoiseDiffReporter',
          namer()->name();
    };
};

if ( !$ENV{RELEASE_TESTING} ) {
    plan( skip_all => 'Author tests not required for installation' );
}
else {
    run_tests();
}
