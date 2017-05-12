package Test::Approvals::Reporters::DiffReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose;
    use Test::Approvals::Reporters;

    has exe  => ( is => 'ro', isa => 'Str', default => q{} );
    has argv => ( is => 'ro', isa => 'Str', default => q{} );
    has reporter => ( is => 'ro' );

    with 'Test::Approvals::Reporters::Win32Reporter';
    with 'Test::Approvals::Reporters::Reporter';
    with 'Test::Approvals::Reporters::EnvironmentAwareReporter';

    sub BUILD {
        my ($self) = @_;
        $self->{reporter} =
          Test::Approvals::Reporters::FirstWorkingReporter->new(
            reporters => [
                Test::Approvals::Reporters::BeyondCompareReporter->new(),
                Test::Approvals::Reporters::CodeCompareReporter->new(),
                Test::Approvals::Reporters::WinMergeReporter->new(),
                Test::Approvals::Reporters::TortoiseDiffReporter->new(),
                Test::Approvals::Reporters::KDiffReporter->new(),
                Test::Approvals::Reporters::P4MergeReporter->new(),
            ]
          );
        return;
    }

    around report => sub {
        my ( $method, $self, $approved, $received ) = @_;
        my $reporter = $self->reporter();
        $reporter->report( $approved, $received );
        return;
    };

    around is_working_in_this_environment => sub {
        my ( $method, $self ) = @_;
        my $reporter = $self->reporter();

        return $reporter->is_working_in_this_environment();
    };

}
__PACKAGE__->meta->make_immutable;
1;
__END__
=head1 NAME

Test::Approvals::Reporters::DiffReporter 

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::DiffReporter version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals qw(verify_ok use_reporter);
    use Test::Approvals::Reporters;
    use Test::More;

    use_reporter('Test::Approvals::Reporters::DiffReporter');
    verify_ok 'Hello World', 'Hello Test';

=head1 DESCRIPTION

A MultiReporter configured to choose the first working diff utility it can find 
and use it for reporting.

=head1 SUBROUTINES/METHODS

=head2 BUILD

Used internally to configure a FirstWorkingReporter with instances of available
diff Reporters.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

=over 4

Moose
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

