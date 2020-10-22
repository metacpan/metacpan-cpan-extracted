package Task::Test::Run::AllPlugins;

use warnings;
use strict;

=head1 NAME

Task::Test::Run::AllPlugins - Specifications for installing all the Test::Run
Plugins

=cut

our $VERSION = '0.0106';

=head1 DESCRIPTION

L<Test::Run>  is an improved
harness for running test files based on the "Test Anything Protocol"
(TAP - L<http://testanything.org/> ), which is commonly used for writing tests
for Perl code, but is otherwise universal.

Installing this Task should get you up-to-speed with Test::Run by installing
all the plugins that are available for it.

=head1 USAGE

From the CPAN or CPANPLUS shell type:

    install Task::Test::Run::AllPlugins

And follow all the depenedencies.

Afterwards, set the environment variable C<HARNESS_PLUGINS> to the following:

    export HARNESS_PLUGINS="ColorSummary ColorFileVerdicts"

Or if you wish to use the Alternate Interpreters plugin as well to:

    export HARNESS_PLUGINS="ColorSummary ColorFileVerdicts AlternateInterpreters"

Then you can use runprove to run and analyze TAP scripts (like CPAN
modules t/*.t files) from the command line:

    runprove t/*.t

If you have written a plugin and wish it to be included in this task, don't
hesitate to contact me: L<http://www.shlomifish.org/me/contact-me/> .

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Test::Run::AllPlugins

You can also look for information at:

=over 4

=item * The Test-Run Homepage

( L<http://web-cpan.shlomifish.org/modules/Test-Run/> )

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Test-Run-AllPlugins>

=item * MetaCPAN

L<http://metacpan.org/release/Task-Test-Run-AllPlugins>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<Task>, L<Test::Run::Obj>, L<Test::Run::Core>, L<Test::Run::CmdLine>.

The documentation of the appropriate plugins.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT.

=cut

1; # End of Task::Test::Run::AllPlugins
