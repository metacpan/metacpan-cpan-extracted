#!perl
use strict;
use warnings;
use 5.010;

our $VERSION = '0.001';

use Test2::V0;

use Carp;
use FileHandle ();
use File::Path qw( make_path );
use File::Spec ();
use File::Temp ();
use Cwd        qw( getcwd abs_path );

use Software::Policies;

my $CONTRIBUTING_PERL_DIST_ZILLA_V1_MARKDOWN = <<'EOF';
## HOW TO CONTRIBUTE

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.

The distribution is managed with Dist::Zilla.  This means than many of the
usual files you might expect are not in the repository, but are generated at
release time, as is much of the documentation.  Some generated files are
kept in the repository as a convenience (e.g. Makefile.PL or cpanfile).

Generally, **you do not need Dist::Zilla to contribute patches**.  You do need
Dist::Zilla to create a tarball.  See below for guidance.

### Getting dependencies

If you have App::cpanminus 1.6 or later installed, you can use `cpanm` to
satisfy dependencies like this:

    $ cpanm --installdeps .

Otherwise, look for either a `Makefile.PL` or `cpanfile` file for
a list of dependencies to satisfy.

### Running tests

You can run tests directly using the `prove` tool:

    $ prove -l
    $ prove -lv t/some_test_file.t

For most of my distributions, `prove` is entirely sufficient for you to test any
patches you have. I use `prove` for 99% of my testing during development.

### Code style and tidying

Please try to match any existing coding style.  If there is a `.perltidyrc`
file, please install Perl::Tidy and use perltidy before submitting patches.

If there is a `tidyall.ini` file, you can also install Code::TidyAll and run
`tidyall` on a file or `tidyall -a` to tidy all files.

### Patching documentation

Much of the documentation Pod is generated at release time.  Some is
generated boilerplate; other documentation is built from pseudo-POD
directives in the source like C<=method> or C<=func>.

If you would like to submit a documentation edit, please limit yourself to
the documentation you see.

If you see typos or documentation issues in the generated docs, please
email or open a bug ticket instead of patching.

### Installing and using Dist::Zilla

Dist::Zilla is a very powerful authoring tool, optimized for maintaining a
large number of distributions with a high degree of automation, but it has a
large dependency chain, a bit of a learning curve and requires a number of
author-specific plugins.

To install it from CPAN, I recommend one of the following approaches for
the quickest installation:

    # using CPAN.pm, but bypassing non-functional pod tests
    $ cpan TAP::Harness::Restricted
    $ PERL_MM_USE_DEFAULT=1 HARNESS_CLASS=TAP::Harness::Restricted cpan Dist::Zilla

    # using cpanm, bypassing *all* tests
    $ cpanm -n Dist::Zilla

In either case, it's probably going to take about 10 minutes.  Go for a walk,
go get a cup of your favorite beverage, take a bathroom break, or whatever.
When you get back, Dist::Zilla should be ready for you.

Then you need to install any plugins specific to this distribution:

    $ cpan `dzil authordeps`
    $ dzil authordeps | cpanm

Once installed, here are some dzil commands you might try:

    $ dzil build
    $ dzil test
    $ dzil xtest

You can learn more about Dist::Zilla at http://dzil.org/
EOF

my $CONTRIBUTING_PERL_DIST_ZILLA_V1_TEXT = <<'EOF';
HOW TO CONTRIBUTE

Thank you for considering contributing to this distribution.  This file
contains instructions that will help you work with the source code.

The distribution is managed with Dist::Zilla.  This means than many of the
usual files you might expect are not in the repository, but are generated at
release time, as is much of the documentation.  Some generated files are
kept in the repository as a convenience (e.g. Makefile.PL or cpanfile).

Generally, **you do not need Dist::Zilla to contribute patches**.  You do need
Dist::Zilla to create a tarball.  See below for guidance.

Getting dependencies

If you have App::cpanminus 1.6 or later installed, you can use `cpanm` to
satisfy dependencies like this:

    $ cpanm --installdeps .

Otherwise, look for either a `Makefile.PL` or `cpanfile` file for
a list of dependencies to satisfy.

Running tests

You can run tests directly using the `prove` tool:

    $ prove -l
    $ prove -lv t/some_test_file.t

For most of my distributions, `prove` is entirely sufficient for you to test any
patches you have. I use `prove` for 99% of my testing during development.

Code style and tidying

Please try to match any existing coding style.  If there is a `.perltidyrc`
file, please install Perl::Tidy and use perltidy before submitting patches.

If there is a `tidyall.ini` file, you can also install Code::TidyAll and run
`tidyall` on a file or `tidyall -a` to tidy all files.

Patching documentation

Much of the documentation Pod is generated at release time.  Some is
generated boilerplate; other documentation is built from pseudo-POD
directives in the source like C<=method> or C<=func>.

If you would like to submit a documentation edit, please limit yourself to
the documentation you see.

If you see typos or documentation issues in the generated docs, please
email or open a bug ticket instead of patching.

Installing and using Dist::Zilla

Dist::Zilla is a very powerful authoring tool, optimized for maintaining a
large number of distributions with a high degree of automation, but it has a
large dependency chain, a bit of a learning curve and requires a number of
author-specific plugins.

To install it from CPAN, I recommend one of the following approaches for
the quickest installation:

    # using CPAN.pm, but bypassing non-functional pod tests
    $ cpan TAP::Harness::Restricted
    $ PERL_MM_USE_DEFAULT=1 HARNESS_CLASS=TAP::Harness::Restricted cpan Dist::Zilla

    # using cpanm, bypassing *all* tests
    $ cpanm -n Dist::Zilla

In either case, it's probably going to take about 10 minutes.  Go for a walk,
go get a cup of your favorite beverage, take a bathroom break, or whatever.
When you get back, Dist::Zilla should be ready for you.

Then you need to install any plugins specific to this distribution:

    $ cpan `dzil authordeps`
    $ dzil authordeps | cpanm

Once installed, here are some dzil commands you might try:

    $ dzil build
    $ dzil test
    $ dzil xtest

You can learn more about Dist::Zilla at http://dzil.org/
EOF

subtest 'Create Contributing' => sub {
    my %wanted = (
        policy   => 'Contributing',
        class    => 'PerlDistZilla',
        version  => 1,
        text     => $CONTRIBUTING_PERL_DIST_ZILLA_V1_MARKDOWN,
        filename => 'CONTRIBUTING.md',
        format   => 'markdown',
    );

    # my %c = Software::Policies->new->create(
    my @p = Software::Policies->new->create(
        policy     => 'Contributing',
        class      => 'PerlDistZilla',
        version    => 1,
        format     => 'markdown',
        attributes => {},
    );
    is( $p[0], \%wanted, 'Contributing (format markdown) is equal' );
    @p = Software::Policies->new->create( policy => 'Contributing' );
    is( $p[0], \%wanted, 'Contributing is equal with default values' );

    # Text
    $wanted{'format'}   = 'text';
    $wanted{'text'}     = $CONTRIBUTING_PERL_DIST_ZILLA_V1_TEXT;
    $wanted{'filename'} = 'CONTRIBUTING.txt';
    @p                  = Software::Policies->new->create(
        policy  => 'Contributing',
        class   => 'PerlDistZilla',
        version => 1,
        format  => 'text',
    );
    is( $p[0], \%wanted, 'Contributing (format text) is equal' );
    done_testing;
};
done_testing;
