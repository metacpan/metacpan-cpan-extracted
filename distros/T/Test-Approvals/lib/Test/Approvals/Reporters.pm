package Test::Approvals::Reporters;
use strict;
use warnings FATAL => qw(all);
use version; our $VERSION = qv('v0.0.5');

use Test::Approvals::Reporters::AndReporter;
use Test::Approvals::Reporters::BeyondCompareReporter;
use Test::Approvals::Reporters::CodeCompareReporter;
use Test::Approvals::Reporters::DiffReporter;
use Test::Approvals::Reporters::FakeReporter;
use Test::Approvals::Reporters::FileLauncherReporter;
use Test::Approvals::Reporters::FirstWorkingReporter;
use Test::Approvals::Reporters::IntroductionReporter;
use Test::Approvals::Reporters::KDiffReporter;
use Test::Approvals::Reporters::P4MergeReporter;
use Test::Approvals::Reporters::TortoiseDiffReporter;
use Test::Approvals::Reporters::WinMergeReporter;

1;
__END__
=head1 NAME

Test::Approvals::Reporters - 'use' all the available reporters

=head1 VERSION

This documentation refers to Test::Approvals::Reporters version v0.0.5

=head1 SYNOPSIS

	use Test::Approvals::Reporters;

=head1 DESCRIPTION

This module imports all known reporter modules into the target namespace.

=head1 SUBROUTINES/METHODS

None.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

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

