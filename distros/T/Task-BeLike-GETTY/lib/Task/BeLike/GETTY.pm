use strict;
use warnings;
package Task::BeLike::GETTY;
BEGIN {
  $Task::BeLike::GETTY::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: be like GETTY (without the insanity hopefully) -- use what drives his gears
$Task::BeLike::GETTY::VERSION = '20150205.000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::BeLike::GETTY - be like GETTY (without the insanity hopefully) -- use what drives his gears

=head1 VERSION

version 20150205.000

=head1 TASK CONTENTS

=head2 Perl itself

=head3 L<perl> 5.010001

You should have at least 5.10.1

=head2 Useful Command-Line Tools

=head3 L<App::Ack>

Because grep is outdated

=head2 Working with CPAN distributions

=head3 L<App::cpanminus>

Because I don't want useless crap on my screen.

=head3 L<App::CPAN::Fresh>

Installs latest version of the dist... for the people who cant wait to get
their own release on other machines ;)

=head2 Object orientated working

=head3 L<Moo>

Cause it cost nothing and makes the code nice.

=head3 L<MooX>

An easier way to load Moo and MooX plugins for it.

=head3 L<Moose>

The ultimate power in the universe to make classes

=head3 L<MooseX::NonMoose>

Sometimes something else wanna be a Moose!

=head2 Application Frameworks

=head3 L<MooX::HasEnv>

Depend attributes on environment variables in L<Moo>.

=head3 L<MooX::Cmd>

L<MooX::Cmd> together with L<MooX::Options> gives you the ability to make easy
multicommand application.

=head3 L<MooX::Options>

=head3 L<MooseX::Getopt>

If you use L<Moose>, then you should go this way for making options possible
in your application.

=head3 L<String::ProgressBar>

Make nice progress bars in your application.

=head2 Event driven, non-blocking environment

=head3 L<Reflex>

Because L<POE> is really outdated (and too complex)

=head3 L<Reflexive::Client::HTTP>

Never saw a non-blocking environment which not used some HTTP client
somewhere in the process hehe :).

=head2 Database

=head3 L<DBIx::Class>

There is no other way to access a database

=head3 L<DBIx::Class::Candy>

Use this to define your L<DBIx::Class> result classes.

=head3 L<DBIx::Class::AlwaysUpdate>

=head3 L<DBIx::Class::TimeStamp>

=head3 L<DBIx::Class::EncodedColumn>

=head3 L<DBIx::Class::InflateColumn::DateTime>

=head3 L<DBIx::Class::InflateColumn::Serializer>

Very useful in combination with L<JSON> to get a simple random data storage
field. 

=head3 L<DBIx::Class::EncodedColumn::Crypt::Eksblowfish::Bcrypt>

Best way to get a transparent (one way) encrypted field, like password.

=head2 Templating

=head3 L<Text::Xslate>

The fastest template engine, but needs a bit more understandment, but can be
used with many template syntaxes (more or less identical of course).

=head2 Web frameworks

=head3 L<Catalyst::Runtime>

For serious web application development

=head3 L<Catalyst::Plugin::ChainedURI>

A more simple way to get a specific url in L<Catalyst> then with the given
tools inside of L<Catalyst>.

=head3 L<Catalyst::Plugin::CustomErrorMessage>

An error should be nice.

=head3 L<Catalyst::Plugin::Session>

=head3 L<Catalyst::Plugin::Session::State::Cookie>

=head3 L<Catalyst::Plugin::Session::Store::File>

=head3 L<Catalyst::Plugin::Unicode::Encoding>

Never forget to load this. You want utf8.

=head3 L<Catalyst::Authentication::Store::DBIx::Class>

=head3 L<Catalyst::Plugin::Authentication>

=head3 L<Catalyst::Plugin::Captcha>

=head3 L<Catalyst::Plugin::StackTrace>

Make a crash more useful, show a stack trace.

=head3 L<Catalyst::View::TT>

=head3 L<Catalyst::View::JSON>

=head3 L<Catalyst::View::Email::Template>

=head3 L<Yeb>

A very simple straightforward Web DSL, perfect for beginners.s

=head3 L<Web::Simple>

For the simple stuff (more for experienced users)

=head3 L<Plack>

The base for all those frameworks, and the best way to make your own base
for a webframework, even tho, you normally should be happy with L<Web::Simple>
and L<Catalyst>, but it gives interesting background knowledge to know
L<Plack> and PSGI. See L<http://plackperl.org/>.

=head3 L<Plack::Middleware::Debug>

The so far best debugging console from the author of L<Plack> directly.

=head2 Web Development Helper

=head3 L<CSS::Minifier::XS>

=head3 L<JavaScript::Minifier>

=head3 L<Twiggy::Server>

An AnyEvent webserver which allows to make websocket servers.

=head3 L<PocketIO>

socket.io compatible websocket implementation.

=head2 Validation

=head3 L<Syccess>

A very simple concept to validate hashs based on any way you want.

=head3 L<Email::Valid>

Best thing so far to check for a valid email.

=head2 Translation

=head3 L<Locale::Simple>

A simple way to integrate B<gettext> translations into Javascript and Perl with
the same API. It has anything included you need, you just need to have the
B<gettext> tools installed. You can check for a tool C<msgfmt> that is inside
there, if you are unsure, if you installed the proper gettext package of your
distribution.

=head2 Installation Tools

=head3 L<Installer>

Install a giant group of requirements (of any kind) automatically into one
directory.

=head2 Tools for authoring CPAN Distributions

=head3 L<Dist::Zilla>

=head3 L<Dist::Zilla::PluginBundle::Author::GETTY>

This pluginbundle gives you directly all L<Dist::Zilla> plugins I use. Its a
package that tries to be very efficient. Many people dislike that it generates
the changes out of the git log. It is btw also used to generate this Task.

=head3 L<File::ShareDir::ProjectDistDir>

Essential for working sane with the share directory of a distribution in
development context.

=head2 Testing

=head3 L<Test::More>

Simple, straightforward, thats what you need.

=head3 L<Test::Dirs>

For comparing resulting directories.

=head3 L<File::Temp>

For getting temporary directories. Very handy for tests.

=head2 Making your own DarkPAN / GreyPAN

=head3 L<CPAN::Repository>

=head3 L<Dist::Data>

=head3 L<Module::Data>

=head3 L<Path::ScanINC>

=head2 Other Libraries I Use

=head3 L<Data::Printer>

Nicest debugging output ever.

=head3 L<DateTime> 0.77

Version 0.77 required because: provides CLDR support with fewest known bugs

Working with timestamps is just wrong.

=head3 L<DateTime::Format::Epoch>

As reference to remind that you can find YOUR specific L<DateTime> string
definition out of the many L<DateTime::Format:: distributions|https://metacpan.org/search?q=DateTime%3A%3AFormat%3A%3A>.

=head3 L<DateTime::Format::Strptime>

A very flexible format handler, if you really cant find what you need.

=head3 L<DateTime::Format::Human::Duration>

A good way to display a time duration to humans.

=head3 L<JSON>

The most effective data storage way ...

=head3 L<JSON::MaybeXS>

... and make it quick!

=head3 L<YAML>

If you want the data in the worst case created or modified by humans, then
this is the way to go.

=head3 L<Path::Tiny>

=head3 L<Path::Class>

=head3 L<IO::All>

The best sugar to access files and their data.

=head3 L<Config::INI>

I like INI files.... dont hate me.

=head3 L<Devel::NYTProf>

The most heavy overall debugging possible. Try it out once, to know what you
have.

=head3 L<Scalar::Util>

Nice toolset, check it out and get it known.

=head3 L<Text::Markdown> 1.0.24

Version 1.0.24 required because: has trust_list_start

For making nice GitHub README and wiki pages.

=head3 L<HTTP::Message>

You will need L<HTTP::Request> and L<HTTP::Response>. Use it with
L<LWP::UserAgent> or L<Reflexive::Client::HTTP>.

=head3 L<LWP::UserAgent>

A simple way to make a blocking HTTP request based on L<HTTP::Request>.

=head3 L<URL::Encode>

URL encoding

=head3 L<URI>

Handling URLs itself, making parameter and so on. Very useful, still dislike
the API somehow.

=head2 Sanity-Check

These are just here to make sure other things work properly.

=head3 L<Mozilla::CA>

=head3 L<Crypt::SSLeay>

=head3 L<LWP::Protocol::https>

=head3 L<IO::Socket::SSL>

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
