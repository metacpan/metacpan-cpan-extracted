package Task::Template::Benchmark;

use warnings;
use strict;

our $VERSION = '1.00';

1;

__END__

=pod

=head1 NAME

Task::Template::Benchmark - Task to install all template engines benchmarked by Template::Benchmark.

=head1 SYNOPSIS

This distribution contains no actual code, it simply exists to provide
a list of dependencies to assist in quickly installing all template engines
and optional dependencies used by L<Template::Benchmark>.

Be warned, between them, the 34 modules installed by this task have a
huge number of dependencies and prerequisites, on a fresh build of Perl
with only Bundle::CPAN installed this will run for over 20 minutes.

To use L<Task::Template::Benchmark> simply type at your CPAN prompt:

  install Task::Template::Benchmark

Or extract the distribution tarball to a directory and do the following:

  perl Build.PL
  ./Build installdeps
  ./Build test
  ./Build install

The current release of L<Task::Template::Benchmark> aims to always track
the dependencies required by the current release of L<Template::Benchmark>.

However, it should also be perfectly safe to use the current
L<Task::Template::Benchmark> with an older install of L<Template::Benchmark>
- you'll most likely only end up installing some extra modules that won't
be used by that older version.

=head1 INCLUDED MODULES

=over

=item Template Benchmark itself:

L<Template:Benchmark>

=item Optional bits for extra L<benchmark_template_engines> behaviour:

L<Term::ProgressBar::Simple>

L<JSON::Any>

=item Modules required by multiple plugins:

L<File::Spec>

L<File::Spec> needed by plugins for:
L<Mojo::Template>, L<Tenjin>, L<Text::MicroMason>, L<Text::Tmpl>.

L<IO::File>

L<IO::File> needed by plugins for:
L<Mojo::Template>, L<Tenjin>.

=item Template Engines:

L<HTML::Template>

L<HTML::Template::Compiled>

L<HTML::Template::Expr>

L<HTML::Template::JIT>

L<HTML::Template::Pro>

L<Mojo>

L<Mojo::Template>

L<NTS::Template>

L<Template::Alloy>

L<Template::Sandbox>

Extras for L<Template::Sandbox>:

L<Cache::CacheFactory>
L<Cache::Cache>
L<Cache::FastMemoryCache>
L<Cache::FastMmap>
L<CHI>

L<Template::Tiny>

L<Template>

Extras for L<Template>:

L<Template::Stash::XS>
L<Template::Parser::CET>

L<Tenjin> 0.05 (pre-0.05 Tenjin was an incompatible API change)

L<Text::ClearSilver>

L<Text::MicroMason>

L<Text::MicroTemplate>

L<Text::MicroTemplate::Extended>

L<Text::Template>

L<Text::Template::Simple>

L<Text::Tmpl>

L<Text::Xslate> 0.1030 (0.1030 required for bridge support)

L<Text::Xslate::Bridge::TT2>

=back

=head1 WINDOWS SUPPORT

Under Windows the following modules are not installed because they
appear to fail on Windows:

=over

=item L<HTML::Template::Compiled>

=item L<HTML::Template::JIT>

=item L<Text::ClearSilver>

=item L<Text::Xslate>

=item L<Text::Xslate::Bridge::TT2>

=item L<Term::ProgressBar::Simple>

These modules appear to have build failures under windows, or prerequisites
that fail to build.

=item L<NTS::Template>

Returns empty content.

=item L<Template::Alloy>

The L<HTML::Template> emulation for L<Template::Alloy> appears to
get confused by the volume letters in Windows filenames.

=item L<Template::Tiny>

=item L<Text::Template::Simple>

Error on attempting to run the template.

=item L<Text::Tmpl>

Returns corrupted output at tail end of template.

=back

=head1 KNOWN ISSUES AND BUGS

None currently known.

=head1 SEE ALSO

L<Template::Benchmark>

=head1 AUTHOR

Sam Graham, C<< <libtemplate-benchmark-perl BLAHBLAH illusori.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-template-benchmark at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Template-Benchmark>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Template::Benchmark


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Template-Benchmark>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Template-Benchmark>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Template-Benchmark>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Template-Benchmark/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sam Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
