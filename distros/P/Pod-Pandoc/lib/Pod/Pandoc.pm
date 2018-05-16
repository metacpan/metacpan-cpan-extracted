package Pod::Pandoc;
use strict;
use warnings;
require 5.010;

our $VERSION = '0.5.0';

use Pod::Simple::Pandoc;
use Pod::Pandoc::Modules;
use App::pod2pandoc;

1;
__END__

=head1 NAME

Pod::Pandoc - process Plain Old Documentation format with Pandoc

=begin markdown

# STATUS

[![Unix Build Status](https://travis-ci.org/nichtich/Pod-Pandoc.svg)](https://travis-ci.org/nichtich/Pod-Pandoc)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/lfskwt20v0ofj5ix?svg=true)](https://ci.appveyor.com/project/nichtich/pod-pandoc)
[![Coverage Status](https://coveralls.io/repos/nichtich/Pod-Pandoc/badge.svg)](https://coveralls.io/r/nichtich/Pod-Pandoc)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Pod-Pandoc.png)](http://cpants.cpanauthors.org/dist/Pod-Pandoc)
[![Code Climate Issue Count](https://codeclimate.com/github/nichtich/Pod-Pandoc/badges/issue_count.svg)](https://codeclimate.com/github/nichtich/Pod-Pandoc)
[![Documentation Status](https://readthedocs.org/projects/pod-pandoc/badge/?version=latest)](http://pod-pandoc.readthedocs.io/?badge=latest)

=end markdown

=head1 DESCRIPTION

The Plain Old Documentation format (Pod) is a markup language used to document
Perl code (see L<perlpod> for reference). Several Perl modules exist to process
and convert Pod into other formats.

Pod::Pandoc is an attempt to unify and extend Pod converting based on the
L<Pandoc|http://pandoc.org/> document converter. Pandoc supports more document
formats in a more detailled and uniform way than any set of Perl modules will
ever do. For this reason Pod::Pandoc provides methods to convert Pod to the
Pandoc document model for further processing with Pandoc.

=head1 OUTLINE

=over

=item

L<pod2pandoc> is a command line script to convert Pod to any format supported
by Pandoc.

=item

L<App::pod2pandoc> provides functionality of L<pod2pandoc> to be used in Perl code.

=item

L<Pod::Simple::Pandoc> converts Pod to the abstract document model of Pandoc.

=item

L<Pod::Pandoc::Modules> manages a set of Pod documents of Perl modules.

=back

=head1 REQUIREMENTS

Installation of this module does not require Pandoc but it is needed to make
actual use of it. See L<http://pandoc.org/installing.html> for installation.

=head1 USAGE EXAMPLES

=head2 Replace L<pod2html>

  # pod2html --infile=input.pm --css=style.css --title=TITLE > output.html
  pod2pandoc input.pm --css=style.css --toc --name -o output.html

Pandoc option C<--toc> corresponds to pod2html option C<--index> and is
disabled by default. pod2pandoc adds title and subtitle from NAME section.

=head2 Replace L<pod2markdown>

  # pod2markdown input.pod
  pod2pandoc input.pod -t markdown

  # pod2markdown input.pod output.md
  pod2pandoc input.pod -o output.md

=head2 GitHub wiki

The L<GitHub wiki of this project|https://github.com/nichtich/Pod-Pandoc/wiki>
is automatically populated with its module documentation.  Wiki pages
are created with L<pod2pandoc> as following (see script C<update-wiki.sh>):

  pod2pandoc lib/ script/ wiki/ --ext md --index Home --wiki -t markdown_github

=head2 Sphinx and Read The Docs

The L<Sphinx documentation generator|https://sphinx-doc.org/> recommends
documents in reStructureText format. It further requires a configuration file
C<conf.py> and some links need to be adjusted because Pandoc does not support
wikilinks in rst output format (see script C<update-docs.sh>:

  pod2pandoc lib/ script/ docs/ --ext rst --wiki -t rst --standalone
  perl -pi -e 's!`([^`]+) <([^>]+)>`__!-e "docs/$2.rst" ? ":doc:`$1 <$2>`" : "`$1 <$2>`__"!e' docs/*.rst
  make -C docs html

The result is published automatically at
L<http://pod-pandoc.rtfd.io/en/latest/Pod-Pandoc.html>.

=head1 SEE ALSO

This module is based on the wrapper module L<Pandoc> to execute pandoc from Perl
and on the module L<Pandoc::Elements> for pandoc document processing.

This module makes obsolete several specialized C<Pod::Simple::...> modules such
as L<Pod::Simple::HTML>, L<Pod::Simple::XHTML>, L<Pod::Simple::LaTeX>,
L<Pod::Simple::RTF> L<Pod::Simple::Text>, L<Pod::Simple::Wiki>, L<Pod::WordML>,
L<Pod::Perldoc::ToToc> etc. It also covers batch conversion such as
L<Pod::Simple::HTMLBatch>, L<Pod::ProjectDocs>, L<Pod::POM::Web>, and
L<Pod::HtmlTree>.

=encoding utf8

=head1 AUTHOR

Jakob Voß E<lt>jakob.voss@gbv.deE<gt>

=head1 CONTRIBUTORS

Benct Philip Jonsson

=head1 COPYRIGHT AND LICENSE

Copyright 2017- Jakob Voß

GNU General Public License, Version 2

=cut

=begin rst

.. toctree::
   :hidden:
   :glob:

   *

=end rst
