package Test::Approvals::Reporters::FirstWorkingReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Carp;
    use File::Spec;
    use List::MoreUtils qw(any);
    use List::Util qw(first);
    use Moose;
    use Moose::Util qw(does_role);

    with 'Test::Approvals::Reporters::MultiReporter';
    with 'Test::Approvals::Reporters::Win32Reporter';
    with 'Test::Approvals::Reporters::Reporter';
    with 'Test::Approvals::Reporters::EnvironmentAwareReporter';

    around report => sub {
        my ( $report_method, $self, $approved, $received ) = @_;

        my $working = first { _is_working($_) } @{ $self->reporters() };

        _assert_found( $working, $received );

        $working->report( $approved, $received );
        return;
    };

    around is_working_in_this_environment => sub {
        my ( $method, $self ) = @_;
        return any { _is_working($_) } @{ $self->reporters() };
    };

    sub _is_working {
        my ($reporter) = @_;
        return does_role( $reporter,
            'Test::Approvals::Reporters::EnvironmentAwareReporter' )
          && $reporter->is_working_in_this_environment();
    }

    sub _assert_found {
        my ( $reporter, $received ) = @_;
        if ( !defined $reporter ) {
            croak
              "FirstWorkingReporter could not find a Reporter for $received";
        }
        return;
    }
}
__PACKAGE__->meta->make_immutable;
1;
__END__
=head1 NAME

Test::Approvals::Reporters::FirstWorkingReporter - Report using the first 
reporter that appears to be working in the test environment.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::FirstWorkingReporter version v0.0.5

=head1 SYNOPSIS
    
    use Test::Approvals::Reporters;

    my @reporters = (
        Test::Approvals::Reporters::BeyondCompareReporter->new(),
        Test::Approvals::Reporters::CodeCompareReporter->new(),
    );

    my $reporter = Test::Approvals::Reporters::FirstWorkingReporter->new(
        reporters => \@reporters
    );

    my $received = 'test.received.txt';
    my $approved = 'test.approved.txt';
    $reporter->report($received, $approved);

=head1 DESCRIPTION

Use this module to create a MultiReporter that chooses the first reporter it can 
find which appears to be working in the test environment.

=head1 SUBROUTINES/METHODS

=head2 report

    my $received = 'test.received.txt';
    my $approved = 'test.approved.txt';
    $reporter->report($received, $approved);

If any reporter is working in the test environment, use it to report.

=head2 is_working_in_this_environment

    my $working = $reporter->is_working_in_this_environment;

If any reporter is working in the test environment, return a true value.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

=over 4

Carp
File::Spec
List::MoreUtils
List::Util
Moose
Moose::Util

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

