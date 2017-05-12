package Test::Approvals::Reporters::BeyondCompareReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose;

    with 'Test::Approvals::Reporters::Win32Reporter';
    with 'Test::Approvals::Reporters::Reporter';
    with 'Test::Approvals::Reporters::EnvironmentAwareReporter';

    sub exe {
        return locate_exe( 'Beyond Compare 3/', 'BCompare.exe' );
    }

    sub argv {
        return default_argv();
    }
}
__PACKAGE__->meta->make_immutable;
1;
__END__
=head1 NAME

Test::Approvals::Reporters::BeyondCompareReporter - Report with BeyondCompare

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::BeyondCompareReporter version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Reporters;

    my $reporter = Test::Approvals::Reporters::BeyondCompareReporter->new();
    $reporter->report( 'r.txt', 'a.txt' );

=head1 DESCRIPTION

This module reports using Beyond Compare 3.  Download Beyond Compare at 
http://www.scootersoftware.com/

=head1 SUBROUTINES/METHODS

=head2 argv

Returns the argument portion expected by the reporter when invoked from the 
command line.

=head2 exe

Returns the path to the reporter executable.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

Make sure you have Beyond Compare installed if you want to use this module.

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

