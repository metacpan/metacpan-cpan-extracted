package SQ;

use strict;
use warnings;

use 5.008;

our $VERSION = '0.0.5';


use Exporter 5.57 'import';

use vars ( qw( @EXPORT $S) );

@EXPORT = ( qw($S) );

$S = q#'#;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQ - easily have a string containing single quote (') from the command line.

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

    $ perl -lp -MSQ -e 's/$S(\w+)$S/$1/g'

=head1 DESCRIPTION

This module can be used from the command line to provide a package-scope
variables that contain a single quote - C<$S> . It should
not be used from a program or a module written in a text editor.

=head1 VERSION

Version 0.0.1

=head1 EXPORTS

=head2 $S

Contains a string of the single quote - “C<'>”.

=head1 DONATIONS

If you find this module or any of my other software useful, then I would
appreciate a donation, either monetary or of a book from my wishlist. For
more information, see:

L<http://www.shlomifish.org/meta/donate/> .

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQ or by email to
bug-sq@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc SQ

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/SQ>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/SQ>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SQ>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/SQ>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/SQ>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/SQ>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/SQ>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/S/SQ>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=SQ>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=SQ>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-sq at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQ>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/shlomif/perl-SQ>

  git clone https://github.com/shlomif/perl-SQ.git

=cut
