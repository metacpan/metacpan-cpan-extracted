package Task::Latemp;
$Task::Latemp::VERSION = '0.0107';
use warnings;
use strict;

use 5.014;

use CGI;
use Class::Accessor;
use Data::Dumper;
use File::Basename;
use File::Find::Rule;
use File::Path;
use Getopt::Long;
use HTML::Latemp::GenMakeHelpers;
use HTML::Latemp::NavLinks::GenHtml::Text;
use HTML::Latemp::News;
use HTML::Widgets::NavMenu;
use Pod::Usage;
use Template;
use YAML;


1; # End of Task::Latemp

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::Latemp - Specifications for modules needed by the Latemp static site generator.

=head1 VERSION

version 0.0107

=head1 DESCRIPTION

Latemp ( L<https://web-cpan.shlomifish.org/latemp/> ) is a static site
generator based on Website Meta Language. This task installs all of its
required dependencies.

=head1 VERSION

version 0.0107

=head1 TASK CONTENTS

=head1 AUTHOR

Shlomi Fish, L<https://www.shlomifish.org/> .

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

L<Task> .

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT / Expat .

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Task-Latemp>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Task-Latemp>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Task-Latemp>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Task-Latemp>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Task-Latemp>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Task::Latemp>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-task-latemp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Task-Latemp>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thewml/latemp>

  git clone ssh://git@github.com:thewml/latemp.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Latemp> or by email to
L<bug-task-latemp@rt.cpan.org|mailto:bug-task-latemp@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Task-Latemp>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Task-Latemp>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Task-Latemp>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Task-Latemp>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Task-Latemp>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Task::Latemp>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-task-latemp at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Task-Latemp>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thewml/latemp>

  git clone ssh://git@github.com:thewml/latemp.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Latemp> or by email to
L<bug-task-latemp@rt.cpan.org|mailto:bug-task-latemp@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
