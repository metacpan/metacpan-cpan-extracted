package Test::Approvals::Reporters::AndReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose;

    has reporters => ( is => 'ro' );

    with 'Test::Approvals::Reporters::Reporter';

    sub report {
        my ( $self, $approved, $received ) = @_;
        foreach my $reporter ( @{ $self->reporters() } ) {
            $reporter->report( $approved, $received );
        }

        return;
    }
}
__PACKAGE__->meta->make_immutable;
1;
__END__
=head1 NAME

Test::Approvals::Reporters::AndReporter - Report with multiple reporters

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::AndReporter version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Reporters;

    my $left  = Test::Approvals::Reporters::FileLauncherReporter->new();
    my $right = Test::Approvals::Reporters::DiffReporter->new();
    my $and   = Test::Approvals::Reporters::AndReporter->new(
        reporters => [ $left, $right ] 
    );

    $and->report( 'r.txt', 'a.txt' );

=head1 DESCRIPTION

This module is a MultiReporter configured to execute every reporter passed into
the constructor.

=head1 SUBROUTINES/METHODS

=head2 report

    $and->report( 'r.txt', 'a.txt' );

Each reporter passed to the constructor in the reporters argument will be 
called by report with the arguments provided to report.

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

