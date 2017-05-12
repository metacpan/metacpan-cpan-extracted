# NAME

Task::BeLike::TOKUHIROM - modules I use

# DESCRIPTION

This [Task](https://metacpan.org/pod/Task) installs modules that I need to work with. They are listed in this distribution's cpanfile.

# MY CRITERION

- I don't like the module breaks backward compatibility.
- I don't like the module makes slow the my script's starting up time.
- Simple and small library is great.
- I don't like the module wraps and it provides ::Easy interface.

    Most of ::Easy stuff does not provides all features.
    A short time later, I need to switch the original library. \*Sigh\*

# TASK CONTENTS

## TOOLCHAIN

- [Minilla](https://metacpan.org/pod/Minilla)

    Minilla is an authoring tool to maintaining CPAN modules.
    It provides best practice for managing your module.

- [App::scan\_prereqs\_cpanfile](https://metacpan.org/pod/App::scan_prereqs_cpanfile)

    Scan prereqs from library code and generate cpanfile.

- [App::cpanminus](https://metacpan.org/pod/App::cpanminus)

    The best CPAN module installer. It's a very simple and useful.
    Zero configuration required. I always use this for install modules.

- [Carton](https://metacpan.org/pod/Carton)

    Carton is a installer for the application. It installs modules locally for
    every applications.

- [File::ShareDir](https://metacpan.org/pod/File::ShareDir)

    File::ShareDir enables share directory for each CPAN modules.
    You can include assets to CPAN module with this module.

- [MetaCPAN::API](https://metacpan.org/pod/MetaCPAN::API)

    It's the best client library for accessing MetaCPAN API.

- [Perl::Build](https://metacpan.org/pod/Perl::Build)

    This library helps to build perl5 binary.

- [plenv](https://github.com/tokuhirom/plenv)

    plenv is yet another perl binary manager.

    Use plenv to pick a Perl version for your application and guarantee that your development environment matches production. Put plenv to work with Carton for painless Perl upgrades and bulletproof deployments.

## DATABASE

I'm using RDBMS for storing data.

- [DBI](https://metacpan.org/pod/DBI)

    DBI is a de facto standard library for accessing RDBMS.

- [DBD::SQLite](https://metacpan.org/pod/DBD::SQLite)

    SQLite3 is the best solution for storing complex data if you want to store
    the data to file.

- [DBD::mysql](https://metacpan.org/pod/DBD::mysql)

    MySQL is also great if you want to store the data from web application.

- [UnQLite](https://metacpan.org/pod/UnQLite)

    [UnQLite](https://metacpan.org/pod/UnQLite) is a great file based key value store.

    [GDBM\_File](https://metacpan.org/pod/GDBM_File) is also great, but it requires external C library.

- [Teng](https://metacpan.org/pod/Teng)

    [Teng](https://metacpan.org/pod/Teng) is an O/R Mapper. It's very thin and fast.

## THREADING

- [Coro](https://metacpan.org/pod/Coro)

    [Coro](https://metacpan.org/pod/Coro) provides cooperative threads. Coro is very useful if you are writing
    I/O intensive script.

## TEXT PROCESSING

- [Spellunker](https://metacpan.org/pod/Spellunker)

    Pure-perl, dictionary included portable spelling checker.

    I use this to checking spelling miss in POD.

- [Pod::Simple](https://metacpan.org/pod/Pod::Simple)

    This is the best POD parser library I guess.

- [Text::CSV\_XS](https://metacpan.org/pod/Text::CSV_XS)

    This is a CSV parser/generator library.

- [Text::Xslate](https://metacpan.org/pod/Text::Xslate)

    The best template engine in Perl5. It's pretty fast.
    I'm use this in my web applications.

- [Text::MicroTemplate](https://metacpan.org/pod/Text::MicroTemplate)

    Is the embedded Perl. It's written in pure perl.
    Then, I'm using this for tiny scripts, toolchain stuff, etc.

## WEB APPLICATION DEVELOPMENT

- [Plack](https://metacpan.org/pod/Plack)

    Plack is the infrastructure for writing web applications.

- [Amon2](https://metacpan.org/pod/Amon2)

    Amon2 is a lightweight, fast, web application framework.

- [Starlet](https://metacpan.org/pod/Starlet)

    Is a fast HTTP server written in Perl5.

- [HTML::FillInForm](https://metacpan.org/pod/HTML::FillInForm)

    Fill the stuff to form.

## IMAGE

- [Imager](https://metacpan.org/pod/Imager)

    Imager is the library for image processing.

## HTML/XML

- [XML::LibXML](https://metacpan.org/pod/XML::LibXML)

    Is the fast XML parser library.

- [HTML::TreeBuilder::XPath](https://metacpan.org/pod/HTML::TreeBuilder::XPath)

    Traverse HTML with XPath.

## OPERATING SYSTEM

- [POSIX::AtFork](https://metacpan.org/pod/POSIX::AtFork)

    [POSIX::AtFork](https://metacpan.org/pod/POSIX::AtFork) makes to run the code when the process was forked.
    I'm run `srand` and `$dbh-`disconnect> after the forking.

- [Parallel::Prefork](https://metacpan.org/pod/Parallel::Prefork)

    I'm use this for writing worker process using Q4M.

- [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple)

    This library detects when the files are changed.

- [Linux::Inotify2](https://metacpan.org/pod/Linux::Inotify2)

    It makes faster the [Filesys::Notify::Simple](https://metacpan.org/pod/Filesys::Notify::Simple)

## NETWORKING

- [Furl](https://metacpan.org/pod/Furl)

    Furl is a fast HTTP client library.

- [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize)

    is great module to scraping.

- [Web::Query](https://metacpan.org/pod/Web::Query)

    enables jQuery like operation for HTML.

- [AnyEvent](https://metacpan.org/pod/AnyEvent)

    [AnyEvent](https://metacpan.org/pod/AnyEvent) is a framework for I/O multiplexing. I'm use this for writing
    servers. See also [Coro](https://metacpan.org/pod/Coro).

## JSON

- [JSON::XS](https://metacpan.org/pod/JSON::XS)

    JSON::XS is pretty fast. I'm use this for the point what needs performance.

- [JSON::PP](https://metacpan.org/pod/JSON::PP)

    JSON::PP is written in pure perl. And it's bundled to latest Perl5.
    I'm use this for writing toolchain related scripts.

## I/O

- [File::pushd](https://metacpan.org/pod/File::pushd)

    Change directory temporarily for a limited scope.

- [File::Find::Rule](https://metacpan.org/pod/File::Find::Rule)

    It's great for finding files.

- [File::Zglob](https://metacpan.org/pod/File::Zglob)

    It provides zsh like glob operation.

        zglob('**/*.{pm,pl}')

## DEVELOPMENT

- [Devel::NYTProf](https://metacpan.org/pod/Devel::NYTProf)

    Is a best profiling library for Perl5.

## CLASS BUILDER

- [Class::Accessor::Lite](https://metacpan.org/pod/Class::Accessor::Lite)

    It's really simple accessor library. It does not need to inherit.

- [Moo](https://metacpan.org/pod/Moo)

    I use this to say "Hey! Please switch to Moo instead of Moose!".

- [Mouse](https://metacpan.org/pod/Mouse)

    I'm using this in my web applications. Because [Text::Xslate](https://metacpan.org/pod/Text::Xslate) depends to
    Mouse.

## TESTING

- [Test::More](https://metacpan.org/pod/Test::More)

    Yes. It's most basic library.

## E-MAIL

- [Email::Sender](https://metacpan.org/pod/Email::Sender)

    I'm using this library to send mails. Email::Sender 1.300000+ is based on Moo.
    There is no reason to use [Email::Send](https://metacpan.org/pod/Email::Send)!

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
