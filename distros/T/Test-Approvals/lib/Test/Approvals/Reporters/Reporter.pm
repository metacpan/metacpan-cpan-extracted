package Test::Approvals::Reporters::Reporter;
use strict;
use warnings FATAL => 'all';
{

    use version; our $VERSION = qv('v0.0.5');
    use Moose::Role;

    has test_name => ( is => 'rw', isa => 'Str', default => q{} );

    requires qw(report);
}
1;
__END__
=head1 NAME

Test::Approvals::Reporters::Reporter - Defines a role for reporters to 
extend.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::Reporter version v0.0.5

=head1 SYNOPSIS

	package Test::Approvals::Reporters::MyCoolReporter;
	{
	    use version; our $VERSION = qv('v0.0.5');
	    use Moose;

	    with 'Test::Approvals::Reporters::Reporter';

	    # you must implement 'report'
	    sub report {
	        my ( $self, $received, $approved, ) = @_;

			# Reporter gives you this member 
	        my $name = $self->test_name;

			# ...
	        return;
	    }
	}

=head1 DESCRIPTION

Test::Approvals::Reporters::Reporter is a Moose::Role that all reporters should 
extend.  By extending this Role you get the 'test_name' attribute for free, and 
are required to implement a method called 'report'.

=head1 SUBROUTINES/METHODS

=head2 report

Callers will expect report to be a member function that takes a reference to 
the Reporter object, the path to the received file and finally the path to the
approved file.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over 4

Moose::Role
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

