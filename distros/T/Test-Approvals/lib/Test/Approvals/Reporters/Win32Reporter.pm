package Test::Approvals::Reporters::Win32Reporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Capture::Tiny qw(:all);
    use File::Touch;
    use FindBin::Real qw(Bin);
    use Moose::Role;
    use Win32::Process;

    requires qw(exe argv);

    sub launch {
        my ( $self, $received, $approved, ) = @_;
        my $exe  = $self->exe();
        my $argv = $self->argv();

        $argv =~ s/RECEIVED/$received/gmisx;
        $argv =~ s/APPROVED/$approved/gmisx;

        my $process;
        Win32::Process::Create( $process, "$exe", "\"$exe\" $argv",
            0, DETACHED_PROCESS, Bin() );
        return;
    }

    sub report {
        my ( $self, $received, $approved, ) = @_;

        $approved = File::Spec->canonpath($approved);
        $received = File::Spec->canonpath($received);
        touch($approved);

        $self->launch( $received, $approved );
        return;
    }

    sub default_argv {
        return '"RECEIVED" "APPROVED"';
    }

    sub locate_exe {
        my ( $relative_path, $exe ) = @_;

        my $find_in_path = sub {
            my ($location) = capture { system 'where', $exe };
            if ( defined $location ) {
                chomp $location;
                return $location;
            }
            return;
        };

        my $find_in_x86 = sub {
            my $location = File::Spec->catfile( 'C:/Program Files (x86)',
                $relative_path, $exe );
            if ( -e $location ) {
                return $location;
            }
            return;
        };

        my $default = sub {
            return File::Spec->catfile( 'C:/Program Files', $relative_path,
                $exe );
        };

        return $find_in_path->() || $find_in_x86->() || $default->();
    }
}

1;
__END__
=head1 NAME

Test::Approvals::Reporters::Win32Reporter - Generic base for creating reporters
that work on Windows.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::Win32Reporter version v0.0.5

=head1 SYNOPSIS

    package Test::Approvals::Reporters::MyCoolReporter;

    use strict;
    use warnings FATAL => 'all';

    {
        use version; our $VERSION = qv('v0.0.5');
        use Moose;

        with 'Test::Approvals::Reporters::Win32Reporter';
        with 'Test::Approvals::Reporters::Reporter';
        with 'Test::Approvals::Reporters::EnvironmentAwareReporter';

        sub exe {
            return locate_exe( 'CoolCo', 'CooDiff.exe' );
        }

        sub argv {
            return default_argv();
        }
    }
    __PACKAGE__->meta->make_immutable;
    1;

=head1 DESCRIPTION

This module provides a common base for reporters on Windows.  By extending this
class, you get a search strategy for locating your reporter, and you don't have
to worry about the details of launching a detatched child process.

=head1 SUBROUTINES/METHODS

=head2 default_argv

    my $argv = $reporter->default_argv();

Retrieve the shell arguments commonly used by diff utilities.

=head2 launch

    my $received = 'test.received.txt';
    my $approved = 'test.approved.txt';
    $reporter->launch($received, $approved);

Create a detached Windows process for the diff utility, passing the new process
the arguments required to compare the approved file with the received file.

=head2 locate_exe

    # Path within "Program Files"
    my $relative_path = 'DiffUtilMaker/SuperDiff';

    # Diff utility executable name
    my $exe = 'SuperDiffUtil.exe';

    my $exe_path = locate_exe($relative_path, $exe);

Search for $exe on the path, and in common locations.  If not found, hope that 
it's underneath the Windows "Program Files" directory.

=head2 report

    my $received = 'test.received.txt';
    my $approved = 'test.approved.txt';
    $reporter->report($received, $approved);

Normalize the paths to received and approved files, then try to launch the diff
utility.    

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over

Capture::Tiny
File::Touch
FindBin::Real
Moose::Role
version
Win32::Process

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

