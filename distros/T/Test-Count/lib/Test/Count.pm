package Test::Count;
$Test::Count::VERSION = '0.0902';
use warnings;
use strict;

use base 'Test::Count::Base';

use Test::Count::Parser;

sub _in_fh
{
    my $self = shift;
    if (@_)
    {
        $self->{'_in_fh'} = shift;
    }
    return $self->{'_in_fh'};
}

sub _assert_prefix_regex
{
    my $self = shift;
    if (@_)
    {
        $self->{'_assert_prefix_regex'} = shift;
    }
    return $self->{'_assert_prefix_regex'};
}

sub _filename
{
    my $self = shift;
    if (@_)
    {
        $self->{'_filename'} = shift;
    }
    return $self->{'_filename'};
}

sub _init
{
    my $self = shift;
    my $args = shift;

    my $in;

    if ( exists( $args->{'filename'} ) )
    {
        $self->_filename( $args->{'filename'} );
        open $in, "<", $self->_filename()
            or die "Could not open '" . $self->_filename() . "' - $!.";
    }
    else
    {
        $in = $args->{'input_fh'};
    }

    $self->_in_fh($in);
    if ( exists( $args->{'assert_prefix_regex'} ) )
    {
        my $re = $args->{'assert_prefix_regex'};
        $self->_assert_prefix_regex( ( ref($re) eq "" ) ? qr{$re} : $re );
    }
    else
    {
        $self->_assert_prefix_regex(qr{# TEST});
    }

    return 0;
}


sub process
{
    my $self = shift;
    my $args = shift;

    my $parser = $args->{parser} || Test::Count::Parser->new();

    $parser->_push_current_filename( $self->_filename );

    my $assert_re = $self->_assert_prefix_regex();

    my @file_lines = readline( $self->_in_fh() );
    close( $self->_in_fh() );

    foreach my $idx ( 0 .. $#file_lines )
    {
        my $line = $file_lines[$idx];

        chomp($line);
        if ( $line =~ /${assert_re}:(.*)$/ )
        {
            $parser->update_assignments(
                {
                    'text' => $1,
                }
            );
        }

        # The \s* is to handle trailing whitespace properly.
        elsif ( $line =~ /${assert_re}((?:[+*].*)?)\s*$/ )
        {
            my $s = $1;
            $parser->update_count(
                {
                    'text' => ( ( $s eq "" ) ? 1 : substr( $s, 1 ) ),
                }
            );
        }
    }
    $parser->_pop_current_filenames();

    return { 'tests_count' => $parser->get_count(), 'lines' => \@file_lines, };
}


1;    # End of Test::Count

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Count - Module for keeping track of the number of tests in a test script.

=head1 VERSION

version 0.0902

=head1 SYNOPSIS

    $ cat "t/mytest.t" | perl -MTest::Count::Filter -e 'filter()'

=head1 DESCRIPTION

Test::Count is a set of perl modules for keeping track of the number of tests
in a test file. It works by putting in comments of the form C<# TEST>
(one test), C<# TEST*$EXPR> or C<# TEST+$EXPR> (both are multiple tests).
Test::Count count these tests throughout the fileand return all of their
results.

One can put any mathematical expressions (using parentheses, C<+>, C<->,
C<*>, C</> and C<%> there).
One can also assign variables using
C<# TEST:$myvar=5+6;$second_var=$myvar+3> and later use them in the add
to count expressions. A C<$var++> construct is also available.

One can find example test scripts under t/.

A simple Vim (L<http://www.vim.org/>) function to update the count of the
tests in the file is:

    function! Perl_Tests_Count()
        %!perl -MTest::Count::Filter -e 'Test::Count::Filter->new({})->process()'
    endfunction

=head1 VERSION

version 0.0902

=head1 FUNCTIONS

=head2 my $counter = Test::Count->new({'input_fh' => \*MYFILEHANDLE});

Creates a new Test::Count object that process the filehandle specified in
C<'input_fh'>. Optional keys are:

=over 4

=item * 'assert_prefix_regex' => qr{; TEST}

A regular expression for specifying the prefix for a "TEST" assertion that
updates the grammar. Defaults to C<"# TEST">.

=back

=head2 $counter->process();

Process the filehandle specified in 'input_fh' in ->new(), and return a
hash ref with the following keys:

=over 4

=item * tests_count

The count of the test.

=item * lines

The lines of the stream as is.

=back

=head1 GRAMMAR DESCRIPTION

You can put any mathematical expressions (using parentheses, C<+>, C<->,
C<*>, C</> and C<%> there).
You can also assign variables using
C<# TEST:$myvar=5+6;$second_var=$myvar+3> and later use them in the add
to count expressions. A C<$var++> construct is also available.
Also available are C<+=>, C<-=> and C<*=>.

You can also do C<# TEST:source "path-to-file-here.txt"> where the filename
comes in quotes, in order to include the filename and process it (similar
to the C-shell or Bash "source" command) . You can use the special variable
C<$^CURRENT_DIRNAME> there for the dirname of the current file.

Finally, C<# TEST*EXPR()> and C<# TEST+$EXPR()> add tests to the count.

=head1 EXAMPLES

=head2 Trivial

The first example is very trivial:

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::More tests => 2;

    # TEST
    ok (1, "True is true.");

    {
        my $val = 'foobar';

        # TEST
        is ($val, 'foobar', 'The variable $val has the right value.');
    }

As you can see, the C<# TEST> comments are very close to the assertions where
they are easily noticable and easy to maintain by the tests (if more tests
are added or removed).

=head2 Loops

Now, let's suppose you have several files which you'd like to make sure
validate according to the spec, and are processed well using the processor.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Test::More tests => 18;
    use IO::All;
    use Test::Differences;

    use MyFormatProcessor;

    # TEST:$num_files=6;
    my @basenames =
    (qw(
        basic
        with_ampersands
        with_comments
        with_bold
        with_italics
        with_bold_and_italics
    ));

    foreach my $basename (@basenames)
    {
        my $processor = MyFormatProcessor->new(
            {
                filename => "t/data/input/$basename.myformat",
            }
        );

        # TEST*$num_files
        ok ($processor,
            "Construction of a processor for '$basename' was successful."
        );

        # TEST*$num_files
        ok (scalar($processor->is_valid()), "'$basename' is valid.");

        # TEST*$num_files
        eq_or_diff ($processor->convert_to_xhtml,
            scalar(io("t/data/want-output/$basename.xhtml")->slurp()),
            "Converting '$basename' is successful."
        );
    }

As you can see, the number of files is kept in one central place, and each
assertion inside the loop is multiplied by it. So if we add or remove files,
we only need to add or remove them from their declarations.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-count at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Count>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Count

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Count>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Count>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Count>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Count>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish.

This program is released under the following license: MIT X11.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/test-count/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Test::Count

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Test-Count>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-Count>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Count>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Test-Count>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Test-Count>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Test-Count>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-Count>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-Count>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::Count>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-count at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Test-Count>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/test-count>

  git clone git://github.com/shlomif/test-count.git

=cut
