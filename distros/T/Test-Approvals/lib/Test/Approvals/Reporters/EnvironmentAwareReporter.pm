package Test::Approvals::Reporters::EnvironmentAwareReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose::Role;

    requires qw(exe);

    sub is_working_in_this_environment {
        my ($self) = @_;
        return ( -e $self->exe() );
    }
}
1;
__END__
=head1 NAME

Test::Approvals::Reporters::EnvironmentAwareReporter

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::EnvironmentAwareReporter version v0.0.5

=head1 SYNOPSIS

	# just mix in with a class that has 'exe' defined
	package Test::Approvals::Reporters::MyCoolReporter;
	{
	    use version; our $VERSION = qv('v0.0.5');
	    use Moose;

		with 'Test::Approvals::Reporters::Reporter';
		with 'Test::Approvals::Reporters::EnvironmentAwareReporter'

		# ...
	}

=head1 DESCRIPTION

Provides a role which Reporters can extend when they want to provide a value 
inidicating whether they work in the test environment.

=head1 SUBROUTINES/METHODS

=head2 is_working_in_this_environment 

    $reporter->is_working_in_this_environment();

Gets a value indicating whether the reporter appears to be working in the test
environment.  By default, this just means that the reporter was able to locate 
it's executable.

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

