use 5.14.0;
use warnings;
package Task::BeLike::RJBS;
# ABSTRACT: be more like RJBS -- use the modules he likes!
$Task::BeLike::RJBS::VERSION = '20150423.001';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::BeLike::RJBS - be more like RJBS -- use the modules he likes!

=head1 VERSION

version 20150423.001

=head1 TASK CONTENTS

=head2 Perl for Perl's Sake

=head3 L<perl> 5.014

Version 5.014 required because: gotta have my "package NAME BLOCK"

=head3 L<App::grindperl>

=head2 Useful Command-Line Tools

=head3 L<App::Ack> 1.82

Version 1.82 required because: a working --pager

=head3 L<App::Nopaste> 1.004

Version 1.004 required because: Gist support with stricter paste validation

=head3 L<App::Whiff>

App::Whiff provides C<whiff>, which replaces C<which>, because C<which> is
stupid.

=head3 L<App::Uni>

This gets us the "uni" command, which lets you run "uni snowman" to copy and
paste the character and look funny on IRC.

=head3 L<File::Rename>

This lets me rename a bunch of files by apply a C<s///> expression, or more.

=head3 L<Unicode::Tussle>

This is a whole bunch of extra utilities for poking through Unicode data.  It's
all cool stuff.

=head2 Tools for Working with the CPAN

=head3 L<perl> 5.14.0

Version 5.14.0 required because: it has package NAME BLOCK

=head3 L<App::cpanminus> 1.1002

Version 1.1002 required because: it has --auto-cleanup

=head3 L<App::cpanoutdated> 0.12

Version 0.12 required because: it won't install old dists

=head3 L<CPAN::Mini> 0.563

=head3 L<Module::Which>

I use F<which_pm> to find the version and location of installed modules, even
if two versions are installed in different parts of C<@INC>.

=head3 L<Pod::Cpandoc>

It's like C<perldoc>, but for stuff you haven't installed (yet?).

=head2 Tools for Building CPAN Distributions

=head3 L<Dist::Zilla> 5

Version 5 required because: encoding!

=head3 L<Dist::Zilla::PluginBundle::RJBS> 5

Version 5 required because: newest available

=head3 L<Perl::Tidy> 20071205

Version 20071205 required because: supports 5.10

=head3 L<Pod::Weaver> 4

Version 4 required because: encoding!

=head2 Application Frameworks

=head3 L<App::Cmd> 0.308

Version 0.308 required because: it has App::Cmd::Setup bugfixes

App::Cmd also gets us Getopt::Long::Descriptive.

=head2 Email-Handling Libraries

=head3 L<Email::Filter> 1.02

Version 1.02 required because: I still use it, for lack of something better

=head3 L<Email::MIME> 1.905

Version 1.905 required because: merged in Creator and Modifier modules; bug fixes

=head3 L<Email::Sender>

=head3 L<Email::Sender::Transport::SQLite>

=head2 Other Libraries I Use

=head3 L<Carp::Always>

=head3 L<Config::INI> 0.011

=head3 L<DBD::SQLite>

=head3 L<Data::GUID> 0.044

Version 0.044 required because: requires a new enough Data::UUID to work around Debian

=head3 L<DateTime> 0.51

Version 0.51 required because: provides CLDR support with fewest known bugs

=head3 L<Devel::Cover>

=head3 L<Devel::NYTProf>

=head3 L<HTML::Element> 3.22

Version 3.22 required because: has proper XML escaping

=head3 L<JSON> 2.12

Version 2.12 required because: fixes unicode handling from ASCII JSON

=head3 L<List::AllUtils>

=head3 L<Log::Dispatchouli> 2.000

Version 2.000 required because: it has Log::Dispatchouli::Global

=head3 L<Moose> 1.19

Version 1.19 required because: it has assert_coerce

=head3 L<MooseX::StrictConstructor>

All constructors must be strict!

=head3 L<namespace::autoclean>

=head3 L<PPI> 1.212

Version 1.212 required because: fixes parsing of package names with leading-digit parts

=head3 L<Params::Util> 0.38

Version 0.38 required because: has fixes to _IDENTIFIER and _CLASS

=head3 L<Plack>

=head3 L<Scalar::Util> 1.18

=head3 L<Sub::Exporter> 0.980

Version 0.980 required because: INIT collector; bug fixes

=head3 L<Term::ReadLine::Gnu> 1

Version 1 required because: improves the debugger

=head3 L<Text::Markdown> 1.0.24

Version 1.0.24 required because: has trust_list_start

=head3 L<Throwable> 0.102080

Version 0.102080 required because: StackTrace::Auto factored out

=head3 L<Throwable::X>

=head3 L<Try::Tiny> 0.007

Version 0.007 required because: exception passed to C<finally>

=head2 Sanity-Check

These are just here to make sure other things work properly.

=head3 L<Mozilla::CA>

=head3 L<Crypt::SSLeay>

=head3 L<LWP::Protocol::https>

=head3 L<IO::Socket::SSL>

=head3 L<Config::GitLike>

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
