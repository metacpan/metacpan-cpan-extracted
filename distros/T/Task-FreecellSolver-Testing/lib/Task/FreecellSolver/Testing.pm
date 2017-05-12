package Task::FreecellSolver::Testing;
our $AUTHORITY = 'cpan:SHLOMIF';

use warnings;
use strict;

use 5.012;


our $VERSION = 'v0.0.11';

# Load the dependencies so we'll be sure they are installed.
use Carp;
use Cwd;
use Data::Dumper;
use Digest::SHA;
use Env::Path;
use File::Path;
use File::Spec;
use File::Which ();
use Games::Solitaire::Verify;
use Inline;
use Inline::C ();
use List::MoreUtils;
use List::Util;
use Moo;
use MooX qw(late);
use Path::Tiny 0.077;
use Storable;
use String::ShellQuote;
use Task::Test::Run::AllPlugins;
use Template;
use Test::Code::TidyAll;
use Test::Data::Split;
use Test::Differences;
use Test::More;
use Test::PerlTidy ();
use Test::Run::CmdLine::Plugin::TrimDisplayedFilenames;
use Test::RunValgrind;
use Test::TrailingSpace ();
use YAML::XS;


1; # End of Task::FreecellSolver::Testing

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::FreecellSolver::Testing - install the CPAN dependencies of the
Freecell Solver test suite.

=head1 VERSION

version v0.0.11

=head1 SYNOPSIS

    $ perl -MCPAN -e 'install "Task::FreecellSolver::Testing"'

=head1 VERSION

version v0.0.11

=head1 TASK CONTENTS

=head1 VERSION

version v0.0.11

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Task::FreecellSolver::Testing

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Task-FreecellSolver-Testing>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Task-FreecellSolver-Testing>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Task-FreecellSolver-Testing>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Task-FreecellSolver-Testing>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Task-FreecellSolver-Testing>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Task-FreecellSolver-Testing>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Task-FreecellSolver-Testing>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Task-FreecellSolver-Testing>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Task-FreecellSolver-Testing>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Task::FreecellSolver::Testing>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-task-freecellsolver-testing at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Task-FreecellSolver-Testing>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fc-solve>

  git clone git://github.com/shlomif/fc-solve.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Task::FreecellSolver::Testing

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Task-FreecellSolver-Testing>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Task-FreecellSolver-Testing>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Task-FreecellSolver-Testing>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Task-FreecellSolver-Testing>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Task-FreecellSolver-Testing>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Task-FreecellSolver-Testing>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Task-FreecellSolver-Testing>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Task-FreecellSolver-Testing>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Task-FreecellSolver-Testing>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Task::FreecellSolver::Testing>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-task-freecellsolver-testing at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Task-FreecellSolver-Testing>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/fc-solve>

  git clone git://github.com/shlomif/fc-solve.git

=cut
