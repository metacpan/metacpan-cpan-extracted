package Test::Approvals::Reporters::FileLauncherReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose;

    with 'Test::Approvals::Reporters::Win32Reporter';
    with 'Test::Approvals::Reporters::Reporter';
    with 'Test::Approvals::Reporters::EnvironmentAwareReporter';

    sub exe {
        return locate_exe( q{}, 'cmd.exe' );
    }

    sub argv {
        return '/C "RECEIVED"';
    }
}
__PACKAGE__->meta->make_immutable;
1;
__END__
=head1 NAME

Test::Approvals::Reporters::FileLauncherReporter - Use Windows file associations
to display the file.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::FileLauncherReporter version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Reporters;

    my $reporter = Test::Approvals::Reporters::KDiffReporter->new();
    $reporter->report( 'r.txt', 'a.txt' );

=head1 DESCRIPTION

Display the received file using whichever editor is associated with the file 
type.

=head1 SUBROUTINES/METHODS

=head2 argv

    my $argv = $reporter->argv();

Retrieve the argument template used to ask the shell to find an application 
to display the file.

=head2 exe

    my $exe = $reporter->exe();

Retrieve the path to the shell.

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

