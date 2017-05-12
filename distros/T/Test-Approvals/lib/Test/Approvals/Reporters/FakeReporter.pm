package Test::Approvals::Reporters::FakeReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose;

    has 'was_called', isa => 'Bool', is => 'rw', default => 0;

    with 'Test::Approvals::Reporters::Reporter';

    sub report {
        my ( $self, $approved, $received ) = @_;
        $self->was_called(1);
        return;
    }
}
__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Test::Approvals::Reporters::FakeReporter - Reporter which doesn't actually do 
anything, but you can check to see if it was called.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::FakeReporter version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Reporters;

    my $reporter = Test::Approvals::Reporters::FakeReporter->new();
    $reporter->report( 'r.txt', 'a.txt' );


=head1 DESCRIPTION

A reporter which does not launch a reporter, but does report when a client tried
to launch a reporter.

=head1 SUBROUTINES/METHODS

=head2 report 

    my $received = 'test.received.txt';
    my $approved = 'test.approved.txt';
    $reporter->report($received, $approved);

Sets a value indicating that report was called.

=head2 was_called

    my $ok = $reporter->was_called();
    ok($ok, 'reporter was called');

Gets a value indicating whether report was called.  Mostly used for mocking 
reporters in tests for Test::Approvals itself.

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

