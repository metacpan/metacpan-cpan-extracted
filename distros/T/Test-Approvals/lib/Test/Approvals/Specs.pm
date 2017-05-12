package Test::Approvals::Specs;

use strict;
use warnings FATAL => qw(all);

use version; our $VERSION = qv('v0.0.5');
use base qw(Exporter);
our @EXPORT_OK = qw(describe it run_tests);

use Test::Builder;
use Readonly;

Readonly my $TEST => Test::Builder->new();

my $context;
my @specs;

sub describe {
    $context = shift;
    my $specs = shift;
    $specs->();
    return;
}

sub it {
    my $name            = shift;
    my $spec            = shift;
    my $current_context = $context;
    push @specs, sub { $spec->("$current_context $name") };
    return;
}

sub run_tests {
    my $other_tests = shift // 0;
    $TEST->plan( tests => ( scalar @specs + $other_tests ) );
    for (@specs) { $_->(); }
    return;
}

1;
__END__
=head1 NAME

Test::Approvals::Specs - Tiny BDD Tools

=head1 VERSION

This documentation refers to Test::Approvals::Specs version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Specs qw(describe it run_tests);
    use Test::More;
    use Bank::Account;

    describe 'A bank account' => sub {
        it 'Holds money' => sub {
            my $name = shift;
            my $bank_account = Bank::Account->new();
            $bank_account->deposit(1, 'Bitcoin');
            is $bank_account->balance, 1, $name;
        };
    };

    run_tests();

=head1 DESCRIPTION

Test::Approvals::Specs represents the minimal subset of BDD testing tools I 
needed to comfertably write the type of tests I like to write.  These methods 
are generally written in the rspec spirit, but I'm not an expert in rspec style
BDD.  I enjoy writing jasmine tests in js (http://pivotal.github.io/jasmine/) 
and using igloo with C++ (http://igloo-testing.org/), and I wanted to bring the
parts I liked to Perl.  There are a couple modules that do something similar 
already, but I really wanted to avoid typing the test name twice, so I created 
a set of tools that pass the name to the executable example.

This is a very minimal approach and probably doesn't support features you might
like, such as 'before_each' and 'before_context', spies, expectations, etc.  I 
didn't need them!  If I ever need them I might add them.  If you need them I'd 
be interested in hearing about it, maybe we can work together to add them.

=head1 SUBROUTINES/METHODS

=head2 describe
    
    describe 'A bank account', sub {
        # ...
    };

'describe' groups a set of examples, which taken together specify some system
behaviour.  

=head2 it

    it 'Holds money', sub {
        my $name = shift;
        my $bank_account = Bank::Account->new();
        $bank_account->deposit(1, 'Bitcoin');
        is $bank_account->balance, 1, $name;
    };

'it' is an executable example of some particular system behavior (in other 
words, a test).  'it' always recieves its own description, decorated by it's 
group description, as the first argument when invoked.  Combining the two 
examples above, the value 'A bank account Holds money' is assigned to $name.

=head2 run_tests

    run_tests();

Execute each example.  Examples do not execute immediately, instead they are
stored until you invoke run_tests.  'run_tests' will count the number of 'it' 
examples and setup your test plan accordingly.  However, each example only 
counts as 1 test, and if you place multiple asserts in your example, you will
need to "balance the books" by passing the number of extra tests to run_tests.

    describe 'A bank account', sub { 
        it 'Holds money', sub {
            my $name = shift;
            my $bank_account = Bank::Account->new();
            $bank_account->deposit(1, 'Bitcoin');
            is  $bank_account->balance, 
                1,
                $name;
            
            # Second assertion!
            is  $bank_account->currency, 
                'Bitcoin',
                "$name in a specific currency";
        };
    };

    run_tests(1); # I have 1 extra assertion

This can also be useful if you have some "plain old tests" mixed in with your 
examples.

    my $bank_account = Bank::Account->new();
    
    # Plain old test not accounted for
    ok defined $bank_account, 'I have a bank account';

    describe 'A bank account', sub { 
        it 'Holds money', sub {
            my $name = shift;
            $bank_account->deposit(1, 'Bitcoin');
            is  $bank_account->balance, 
                1,
                $name;
        };
    };

    run_tests(1); # Account for the plain old test

While this can be useful when migrating legacy tests, I don't reccomend it.  
'plan' is my least favorite aspect of the Perl test ecosystem, so I try to 
avoid planning by always using examples, and always using one assertion per 
example.  However, this functionality is there if you need it.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over

Exporter
Readonly
Test::Builder
version

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Windows-only.  Linux/OSX/other support will be added when time and access to 
those platforms permit.

=head1 AUTHOR

Jim Counts - @jamesrcounts

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Jim Counts

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

