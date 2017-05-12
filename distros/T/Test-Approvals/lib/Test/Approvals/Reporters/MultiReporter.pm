package Test::Approvals::Reporters::MultiReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose::Role;

    has reporters => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
    has exe       => ( is => 'rw', isa => 'Str',      default => q{} );
    has argv      => ( is => 'rw', isa => 'Str',      default => q{} );
}

1;
__END__
=head1 NAME

Test::Approvals::Reporters::MultiReporter - Provides a role for aggregate 
reporters to extend.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::MultiReporter version v0.0.5

=head1 SYNOPSIS

    package Test::Approvals::Reporters::MyCoolMultiReporter;

    use strict;
    use warnings FATAL => 'all';

    {
        use Moose;
        use version; our $VERSION = qv('v0.0.5');

        with 'Test::Approvals::Reporters::Reporter';
        with 'Test::Approvals::Reporters::MultiReporter';

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

=head1 DESCRIPTION

The MultiReporter module provides a base which you can extend to create 
aggregate reporters.  You are free to execute every reporter in the aggregate or
to choose just one at runtime.

=head1 SUBROUTINES/METHODS

=head2 argv

	$reporter->argv('"APPROVED" "RECEIVED"');
    my $argv = $reporter->argv();
    
Gets or sets the argument template used to invoke the reporter from the shell.  
The extending class can set this value for objects that expect it to be set.

=head2 exe

	$reporter->exe('SuperDiff.exe');
    my $exe = $reporter->exe();

Gets or sets the path to the reporter's executable.  The extending class can 
set this value for objects that expect it to be set.

=head2 reporters

	my $reporters_ref = $reporter->reporters();

Retrieve the collection of reporters configured for this aggregate.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

Make sure you have P4Merge installed if you want to use this module.

=head1 DEPENDENCIES

=over 4

use Moose
use version

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

