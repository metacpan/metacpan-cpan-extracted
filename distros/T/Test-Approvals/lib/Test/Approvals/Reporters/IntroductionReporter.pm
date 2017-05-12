package Test::Approvals::Reporters::IntroductionReporter;

use strict;
use warnings FATAL => 'all';
use version; our $VERSION = qv('v0.0.5');

{
    use Moose;
    use Test::Builder;

    with 'Test::Approvals::Reporters::Reporter';

    sub report {
        my $message = <<'EOF';

Welcome to ApprovalTests for Perl (Test::Approvals).
ApprovalTests use a reporter to show you results when your test fails.
For example, you could use a diff tool, or simply display the output.
You can find several reporters under Test::Approvals::Reporters, or 
create your own by implementing the Test::Approvals::Reporters::Reporter 
role.  
EOF
        my $test = Test::Builder->new();
        $test->diag($message);
        return;
    }

}
__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Test::Approvals::Reporters::IntroductionReporter - Print diagnostic message 
explaining reporter usage.

=head1 VERSION

This documentation refers to Test::Approvals::Reporters::IntroductionReporter version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Reporters;

    my $reporter = Test::Approvals::Reporters::IntroductionReporter->new();
    $reporter->report( 'r.txt', 'a.txt' );

=head1 DESCRIPTION

This provides help for newbies who don't know about reporters, or for veterans 
who forget to configure thier reporter.  It is the default reporter used by 
Test::Approvals when none is expicitly configured.

=head1 SUBROUTINES/METHODS

=head2 report

    my $received = 'test.received.txt';
    my $approved = 'test.approved.txt';
    $reporter->report($received, $approved);

Print diagnostic message on failure.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

=over 4

Moose
Test::Builder
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

