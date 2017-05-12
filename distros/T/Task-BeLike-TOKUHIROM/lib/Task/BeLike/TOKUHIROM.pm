package Task::BeLike::TOKUHIROM;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.02";



1;
__END__

=encoding utf-8

=head1 NAME

Task::BeLike::TOKUHIROM - modules I use

=head1 DESCRIPTION

This L<Task> installs modules that I need to work with. They are listed in this distribution's cpanfile.

=head1 MY CRITERION

=over 4

=item I don't like the module breaks backward compatibility.

=item I don't like the module makes slow the my script's starting up time.

=item Simple and small library is great.

=item I don't like the module wraps and it provides ::Easy interface.

Most of ::Easy stuff does not provides all features.
A short time later, I need to switch the original library. *Sigh*

=back

=head1 TASK CONTENTS

=head2 TOOLCHAIN

=over 4

=item L<Minilla>

Minilla is an authoring tool to maintaining CPAN modules.
It provides best practice for managing your module.

=item L<App::scan_prereqs_cpanfile>

Scan prereqs from library code and generate cpanfile.

=item L<App::cpanminus>

The best CPAN module installer. It's a very simple and useful.
Zero configuration required. I always use this for install modules.

=item L<Carton>

Carton is a installer for the application. It installs modules locally for
every applications.

=item L<File::ShareDir>

File::ShareDir enables share directory for each CPAN modules.
You can include assets to CPAN module with this module.

=item L<MetaCPAN::API>

It's the best client library for accessing MetaCPAN API.

=item L<Perl::Build>

This library helps to build perl5 binary.

=item L<plenv|https://github.com/tokuhirom/plenv>

plenv is yet another perl binary manager.

Use plenv to pick a Perl version for your application and guarantee that your development environment matches production. Put plenv to work with Carton for painless Perl upgrades and bulletproof deployments.

=back

=head2 DATABASE

I'm using RDBMS for storing data.

=over 4

=item L<DBI>

DBI is a de facto standard library for accessing RDBMS.

=item L<DBD::SQLite>

SQLite3 is the best solution for storing complex data if you want to store
the data to file.

=item L<DBD::mysql>

MySQL is also great if you want to store the data from web application.

=item L<UnQLite>

L<UnQLite> is a great file based key value store.

L<GDBM_File> is also great, but it requires external C library.

=item L<Teng>

L<Teng> is an O/R Mapper. It's very thin and fast.

=back

=head2 THREADING

=over 4

=item L<Coro>

L<Coro> provides cooperative threads. Coro is very useful if you are writing
I/O intensive script.

=back

=head2 TEXT PROCESSING

=over 4

=item L<Spellunker>

Pure-perl, dictionary included portable spelling checker.

I use this to checking spelling miss in POD.

=item L<Pod::Simple>

This is the best POD parser library I guess.

=item L<Text::CSV_XS>

This is a CSV parser/generator library.

=item L<Text::Xslate>

The best template engine in Perl5. It's pretty fast.
I'm use this in my web applications.

=item L<Text::MicroTemplate>

Is the embedded Perl. It's written in pure perl.
Then, I'm using this for tiny scripts, toolchain stuff, etc.

=back

=head2 WEB APPLICATION DEVELOPMENT

=over 4

=item L<Plack>

Plack is the infrastructure for writing web applications.

=item L<Amon2>

Amon2 is a lightweight, fast, web application framework.

=item L<Starlet>

Is a fast HTTP server written in Perl5.

=item L<HTML::FillInForm>

Fill the stuff to form.

=back

=head2 IMAGE

=over 4

=item L<Imager>

Imager is the library for image processing.

=back

=head2 HTML/XML

=over 4

=item L<XML::LibXML>

Is the fast XML parser library.

=item L<HTML::TreeBuilder::XPath>

Traverse HTML with XPath.

=back

=head2 OPERATING SYSTEM

=over 4

=item L<POSIX::AtFork>

L<POSIX::AtFork> makes to run the code when the process was forked.
I'm run C<srand> and C<$dbh->disconnect> after the forking.

=item L<Parallel::Prefork>

I'm use this for writing worker process using Q4M.

=item L<Filesys::Notify::Simple>

This library detects when the files are changed.

=item L<Linux::Inotify2>

It makes faster the L<Filesys::Notify::Simple>

=back

=head2 NETWORKING

=over 4

=item L<Furl>

Furl is a fast HTTP client library.

=item L<WWW::Mechanize>

is great module to scraping.

=item L<Web::Query>

enables jQuery like operation for HTML.

=item L<AnyEvent>

L<AnyEvent> is a framework for I/O multiplexing. I'm use this for writing
servers. See also L<Coro>.

=back

=head2 JSON

=over 4

=item L<JSON::XS>

JSON::XS is pretty fast. I'm use this for the point what needs performance.

=item L<JSON::PP>

JSON::PP is written in pure perl. And it's bundled to latest Perl5.
I'm use this for writing toolchain related scripts.

=back

=head2 I/O

=over 4

=item L<File::pushd>

Change directory temporarily for a limited scope.

=item L<File::Find::Rule>

It's great for finding files.

=item L<File::Zglob>

It provides zsh like glob operation.

    zglob('**/*.{pm,pl}')

=back

=head2 DEVELOPMENT

=over 4

=item L<Devel::NYTProf>

Is a best profiling library for Perl5.

=back

=head2 CLASS BUILDER

=over 4

=item L<Class::Accessor::Lite>

It's really simple accessor library. It does not need to inherit.

=item L<Moo>

I use this to say "Hey! Please switch to Moo instead of Moose!".

=item L<Mouse>

I'm using this in my web applications. Because L<Text::Xslate> depends to
Mouse.

=back

=head2 TESTING

=over 4

=item L<Test::More>

Yes. It's most basic library.

=back

=head2 E-MAIL

=over 4

=item L<Email::Sender>

I'm using this library to send mails. Email::Sender 1.300000+ is based on Moo.
There is no reason to use L<Email::Send>!

=back

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

