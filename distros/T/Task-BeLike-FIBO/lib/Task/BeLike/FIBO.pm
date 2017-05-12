package Task::BeLike::FIBO;

our $VERSION = '0.19';

1;

__END__

=encoding utf8

=head1 NAME

Task::BeLike::FIBO -- Leonardo Pisano a.k.a. Fibonacci

=begin HTML

<p><a href="https://metacpan.org/pod/Task::BeLike::FIBO" target="_blank"><img alt="CPAN version" src="https://badge.fury.io/pl/Task-BeLike-FIBO.svg"></a> <a href="https://travis-ci.org/fibo/Task-BeLike-FIBO-pm" target="_blank"><img alt="Build Status" src="https://travis-ci.org/fibo/Task-BeLike-FIBO-pm.svg?branch=master"></a></p>

=end HTML

=head1 SYNOPSIS

Read how I create Perl packages

    cpan Task::BeLike::FIBO
    perldoc Task::BeLike::FIBO

Create a CPAN package

    mkdir My-Package-pm
    cd My-Package-pm
    wget -q http://g14n.info/Task-BeLike-FIBO-pm/scaffolding -O - | bash

=head1 DESCRIPTION

Hi! I am L<FIBO|https://metacpan.org/author/FIBO>, an italian mathematician. I graduated in 2005 at L<Università degli Studi di Genova|http://www.dima.unige.it/> and since then I work doing Business Intelligence and Web Analytics. My boss said: you need Perl. So I started using this language. I like many programming languages, but, Perl really help me to pay my rent.

This is a primary about my habits and a collection of modules I use when I write Perl code.

=head1 PACKAGE GUIDELINES

Here a C<package> refers to a distribution, a set of Perl modules which could be uploaded to L<PAUSE|http://pause.perl.org/>.

Do not get crazy with automatic generators. I am a mathematician and a coder, not a corporation.

Every package is different and has different needings.

Just use copy and paste and your brain!

The smack of a L<DRY|http://en.wikipedia.org/wiki/Don't_repeat_yourself> L<KISS|http://en.wikipedia.org/wiki/KISS_principle> is not that bad.

Learn from nature: stay as minimal as possible.

=head2 FILES

Follows a list of sample files I usually include in a package, C<My::Package> for instance.

I use to create a L<GitHub|https://github.com/> repo named C<My-Package-pm>.

I also use L<Travis CI|https://travis-ci.org/>.

And yes, L<Task::BeLike::FIBO> was created with these guidelines too! So it is a good example of a meta package (I am a mathematician, I told you ☺).

=over 4

=item *

lib/My/Package.pm

This is the main file of the package and looks something like this

    package My::Package;

    our $VERSION = '0.01';

    1;

    __END__

    =encoding utf8

    =head1 NAME

    My::Package -- is yet another Perl package

    =begin HTML

    <p><a href="https://metacpan.org/pod/My::Package" target="_blank"><img alt="CPAN version" src="https://badge.fury.io/pl/My-Package.svg"></a> <a href="https://travis-ci.org/fibo/My-Package-pm" target="_blank"><img alt="Build Status" src="https://travis-ci.org/fibo/My-Package-pm.svg?branch=master"></a></p>

    =end HTML

    =head1 SYNOPSIS

        package Your:Package;
        use My::Package;

        # Create a My::Package instance.
        my $foo = My::Package->new;

        # foo goes to a bar, ehm ... to have a coffee.
        $foo->bar;

    =head1 DESCRIPTION

    This is a description of what <My::Package> does, why you maybe want to use it, the motivations behind him.

    =head1 COPYRIGHT AND LICENSE

    This software is copyright © 2015 by L<G. Casati|http://g14n.info>.

    This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

    =cut

=item *

README.md

    My-Package
    ==========

    My-Package description ...

    To install, pray the mantra

        perl Makefile.PL
        make
        make test
        make install

    For more information point your browser to [online docs](https://metacpan.org/pod/My::Package).

    --------
    [![CPAN version](https://badge.fury.io/pl/My-Package.svg)](https://metacpan.org/pod/My::Package)
    [![Build Status](https://travis-ci.org/fibo/My-Package-pm.png?branch=master)](https://travis-ci.org/fibo/My-Package-pm)

Yes, it is always a good idea to add a README. If the package is not open sourced, i.e. will be delivered to a customer on premise and will not be hosted on GitHub, create a README.txt instead.

=item *

.travis.yml

Get it with this command

    $ wget http://g14n.info/Task-BeLike-FIBO-pm/travis.yml -O .travis.yml

=item *

.gitignore

Get it with this command

    $ wget http://g14n.info/Task-BeLike-FIBO-pm/gitignore -O .gitignore

=item *

Makefile.PL

    use strict;
    use warnings;

    use ExtUtils::MakeMaker 6.64;

    WriteMakefile(
        ABSTRACT_FROM => 'lib/My/Package.pm',
        VERSION_FROM  => 'lib/My/Package.pm',
        AUTHOR        => 'G. Casati <fibo@cpan.org>',
        NAME          => 'My::Package',
        LICENSE      => 'artistic_2',
        MIN_PERL_VERSION => '5.12.0',
        META_MERGE => {
            resources => {
                homepage   => 'https://metacpan.org/pod/My::Package',
                license    => 'http://g14n.info/artistic-license',
                repository => 'https://github.com/fibo/My-Package-pm',
                bugtracker => 'https://github.com/fibo/My-Package-pm/issues'
            },
        },
        PREREQ_PM => {
            # 'Some::Package' => '0',
            # 'Other::Package' => '1.2.3'
        },
        # EXE_FILES => ['bin/foo', 'bin/bar'],
        BUILD_REQUIRES => {
            'ExtUtils::MakeMaker' => '6.64'
        },
        test => { TESTS => 't/*.t' },
        TEST_REQUIRES => {
            'Test::Compile'      => '1.2.1',
            'Test::More'         => '1.001009',
            'Test::Pod'          => '1.48'
        }
    );

A note about versions in C<PREREQ_PM>: keep in mind that when specifying a version for core modules, it should match the version shipped with Perl version C<MIN_PERL_VERSION>.

The L<corelist> app is your friend.

For example if I want to figure out which version of L<File::Path> I should require, if the lower Perl version I am supporting is C<5.8.0> I launch

    $ corelist -a File::Path | grep v5.8.0
      v5.8.0     1.05

so I know I should go for C<1.05>.

Note that C<MIN_PERL_VERSION> defaults to C<5.12.0>, which is the first modern Perl release, you know. See also L<Perl 5.12 for Everyday Use|http://www.slideshare.net/rjbs/perl-512-for-everyday-use>.
Anyway, I admire a lot the veterans that dig into ancient versions of Perl and support them in their packages.

=item *

MANIFEST.SKIP

Get it with this command

    $ wget http://g14n.info/Task-BeLike-FIBO-pm/MANIFEST.SKIP

=item *

Changes

It is considered a good habit to keep track of at least major changes to inform users what they should expect when upgrading version.

    0.01 2014-12-02
    + First release

=back

=head2 WORKFLOW

=over 4

=item *

Start a feature branch

    $ git checkout -b somefeature

=item *

Write documentation about new feature. Then write tests to check it and code to implement it.

=item *

Run tests

    $ prove -l --state=save

=item *

If some test does not pass, fix code and run tests that failed

    $ prove -l --state=save,failed

=item *

Commit changes

    $ git commit -am 'added some feature'

Merge feature branch and push

    $ git rebase master
    $ git checkout master
    $ git merge somefeature
    $ git push

Delete feature branch

    $ git branch -d somefeature

=item *

Update version, usually in file C<lib/My/Package.pm>.

Use L<Semantic Versioning|http://semver.org/>.

Check that C<Changes> file is updated with information about modifications done.

Update code coverage report if it is in place, see L<CODE COVERAGE/#CODE-COVERAGE> section.

Update GitHub Pages if used, see L<GITHUB PAGES/#GITHUB-PAGES> section.

Create a new release

    $ perl Makefile.PL
    $ make
    $ make test
    $ make manifest
    $ make dist
    $ make realclean

Create a git tag

    $ git tag v0.01
    $ git push origin v0.01

=item *

Upload to L<PAUSE|http://pause.perl.org/>

    $ cpan-upload -u fibo My-Package-0.01.tar.gz
    PAUSE Password:
    registering upload with PAUSE web server
    POSTing upload for My-Package-0.01.tar.gz to https://pause.perl.org/pause/authenquery
    PAUSE add message sent ok [200]

=back

=head1 STUFF INCLUDED

=over 4

=item *

L<App::Ack>

Yes, I was hooked by L<ack>. See also L<ack.vim|https://github.com/mileszs/ack.vim> and L<ack-tutorial|https://github.com/djanowski/ack-tutorial>.

=item *

L<CPAN>

See how to setup L<A CPAN client that works like a charm|http://g14n.info/2014/03/a-cpan-client-that-works-like-charm>.

=item *

L<CPAN::Uploader> to release modules using a cli. It also depends on L<LWP::Protocol::https> which depends on L<IO::Socket::SSL> which I think L<should be a core module|http://blogs.perl.org/users/chris_fedde/2013/03/how-do-we-know-when-a-module-is-depricated.html#comment-1460139>.

=item *

L<Devel::Cover> to add code coverage metrics. It is installed only for Perl E<lt>C<v5.22> otherwise, at the time of this writing (2015-07-05) it will fail installation.

=item *

L<ExtUtils::MakeMaker> version C<6.64>, cause I use the C<TEST_REQUIRES> option.

=item *

L<Module::CoreList>

It is a core module since Perl C<v5.8.9>.

=item *

L<Perl::Tidy>

Get a C<.perltidyrc> file

    $ wget http://g14n.info/Task-BeLike-FIBO-pm/perltidyrc -O .perltidyrc

However, do not indent every source file automatically. Indent by hand and use your creativity.

See Perl section in L<My Vim preferences|http://g14n.info/2013/07/my-vim-configuration#perl> to see how you can use L<perltidy> with Vim.

=item *

L<PPI::HTML>

Used to generate code coverage reports with highlighted syntax.

=item *

L<Test::Compile>

Create a C<t/_compile.t> file

    $ mkdir -p t; wget http://g14n.info/Task-BeLike-FIBO-pm/t/compile.t -O t/_compile.t

=item *

L<Test::More>

=item *

L<Test::Pod>

Create a C<t/_pod.t> file

    $ mkdir -p t; wget http://g14n.info/Task-BeLike-FIBO-pm/t/pod.t -O t/_pod.t

=item *

L<Term::ReadLine::Perl> and L<Term::ReadKey> to L<enable cpan history|http://g14n.info/2014/03/a-cpan-client-that-works-like-charm/#enable-history> of L<cpan> client.

=item *

L<V>

I find it very comfortable to know a package C<Foo> version with

    $ perl -MV=Foo

=back

=head1 MISCELLANEA

=head2 GITHUB PAGES

It can be useful to put some content online, and L<GitHub Pages|https://pages.github.com/> is really comfortable.

Just create a gh-pages folder

    $ mkdir gh-pages

Add some content, commit and then push it on C<gh-pages> branchusing C<git subtree>

    $ git commit -a
    $ git subtree --prefix gh-pages push origin gh-pages

Since I have a C<CNAME> file in my L<fibo.github.io|https://github.com/fibo/fibo.github.io> repo, where C<fibo> is my GitHub username, if I add C<somefile> to C<gh-pages> folder

    $ touch gh-pages/somefile

if my repo name is C<My-Package-pm>, it will be served with url C<http://g14n.info/My-Package-pm/somefile> with proper mime type.

=head2 CODE COVERAGE

Create a folder that will contain code coverage metrics report

    $ mkdir -p gh-pages/code

Run tests with a L<Devel::Cover> harness, it will take more time than running bare tests

    $ export HARNESS_PERL_SWITCHES=-MDevel::Cover
    $ prove -l

Remove harness flag, otherwise all tests in your current session will run and compute coverage.

    $ unset HARNESS_PERL_SWITCHES

Generate html report

    $ cover -outputdir gh-pages/code -report html_basic

See also L<GitHub Pages|#GITHUB-PAGES> section for instructions about how to commit generated html report.

Don't forget to add a link to the html report somewhere in your documentation, something like

    =head1 CODE COVERAGE

    Code coverage metrics report available L<here|http://g14n.info/My-Package-pm/code/coverage.html>

=head2 VERSION NUMBERS IDIOSYNCRASY

Avoid to release versions like C<0.13> or even worse C<1.13> or any number that do not make you feel comfortable: skip it and go straight to C<0.14>! You never knows which strange entanglements there are in this Universe.

=head1 CODE COVERAGE

Code coverage metrics report available L<here|http://g14n.info/Task-BeLike-FIBO-pm/code/coverage.html>. By the way, tests in this C<meta> package are not relevant.

=head1 COPYRIGHT AND LICENSE

This software is copyright © 2015 by L<G. Casati|http://g14n.info>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

