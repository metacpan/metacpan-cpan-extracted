#! perl
use strict;
use warnings FATAL => qw(all);
use autodie;
use version; our $VERSION = qv('v0.0.5');

use Test::Approvals::Specs qw(describe it run_tests);
use Test::Approvals
  qw(verify verify_dump use_reporter reporter use_name use_name_in namer);
use Test::More;

use Path::Class;

describe 'An Approval', sub {
    use_reporter('Test::Approvals::Reporters::FakeReporter');
    it 'Reports failure using the configured reporter', sub {
        my ($spec) = @_;

        use_name($spec);
        verify('Hello');
        ok reporter()->was_called, $spec;
        unlink namer()->get_received_file('txt');
    };

    it 'Can generate names in any directory' => sub {
        my ($spec) = @_;
        my $expected =
            'C:\tmp\approvals.t.'
          . 'an_approval_can_generate_names_in_any_directory'
          . '.received.txt';
        use_name_in( $spec, 'C:\tmp' );
        is namer()->get_received_file('txt'), $expected, namer()->name;
    };

    it 'Still provides expected name for names in other directory' => sub {
        my ($spec) = @_;
        use_name_in( $spec, 'C:\tmp' );
        is $spec, namer()->name, $spec;
    };

    it 'Can accept a Path-Class object as the dir' => sub {
        my $spec = shift;
        use_name_in( $spec, dir('C:\tmp') );
        is namer()->directory, 'C:\tmp', namer()->name;
    };

    it 'Can consistently dump data structures to strings' => sub {
        use_reporter('Test::Approvals::Reporters::DiffReporter');
        use_name(shift);
        my %person =
          ( ssn => 'ABC123', lname => 'Flintrock', fname => 'Fred', );
        verify_dump \%person;
    };
};

run_tests();
