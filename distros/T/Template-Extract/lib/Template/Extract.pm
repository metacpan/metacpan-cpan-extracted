package Template::Extract;
$Template::Extract::VERSION = '0.50';
use strict;
use warnings;
use 5.006;
use constant RUN_CLASS     => ( __PACKAGE__ . '::Run' );
use constant COMPILE_CLASS => ( __PACKAGE__ . '::Compile' );
use constant PARSER_CLASS  => ( __PACKAGE__ . '::Parser' );

our ( $DEBUG, $EXACT );

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    my $run_class     = $class->RUN_CLASS;
    my $compile_class = $class->COMPILE_CLASS;
    my $parser_class  = $class->PARSER_CLASS;

    foreach my $subclass ( $run_class, $compile_class, $parser_class ) {
        ## no critic
        no strict 'refs';
        $class->load($subclass);
        *{"$subclass\::DEBUG"} = *DEBUG;
        *{"$subclass\::EXACT"} = *EXACT;
    }

    bless(
        {
            run_object     => $run_class->new(@_),
            compile_object => $compile_class->new(@_),
            parser_object  => $parser_class->new(@_),
        },
        $class
    );
}

sub load {
    my ( $self, $class ) = @_;
    $class =~ s{::}{/}g;
    ## no critic
    require "$class.pm";
}

sub extract {
    my $self     = shift;
    my $template = shift;

    $self->run( $self->compile($template), @_ );
}

sub compile {
    my $self     = shift;
    my $template = shift;
    $self->{compile_object}->compile( $template, $self->{parser_object} );
}

sub run {
    my $self = shift;
    $self->{run_object}->run(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Extract - Use TT2 syntax to extract data from documents

=head1 VERSION

version 0.50

=head1 SYNOPSIS

    use Template::Extract;
    use Data::Dumper;

    my $obj = Template::Extract->new;
    my $template = << '.';
    <ul>[% FOREACH record %]
    <li><A HREF="[% url %]">[% title %]</A>: [% rate %] - [% comment %].
    [% ... %]
    [% END %]</ul>
    .

    my $document = << '.';
    <html><head><title>Great links</title></head><body>
    <ul><li><A HREF="http://slashdot.org">News for nerds.</A>: A+ - nice.
    this text is ignored.</li>
    <li><A HREF="http://microsoft.com">Where do you want...</A>: Z! - yeah.
    this text is ignored, too.</li></ul>
    .

    print Data::Dumper::Dumper(
        $obj->extract($template, $document)
    );

=head1 DESCRIPTION

This module adds template extraction functionality to the B<Template>
toolkit.  It can take a rendered document and its template together, and
get the original data structure back, effectively reversing the
C<Template::process> function.

=head1 VERSION

This document describes version 0.41 of Template::Extract, released
October 16, 2007.

=head1 METHODS

=head2 new(\%options)

Constructor.  Currently all options are passed into the underlying
C<Template::Parser> object.  The same set of options are also passed to classes
responsible to compile and run the extraction process, but they are currently
ignored.

=head2 extract($template, $document, \%values)

This method takes three arguments: the template string, or a reference to
it; a document string to match against; and an optional hash reference to
supply initial values, as well as storing the extracted values into.

The return value is C<\%values> upon success, and C<undef> on failure.
If C<\%values> is omitted from the argument list, a new hash reference
will be constructed and returned.

Extraction is done by transforming the result from B<Template::Parser>
to a highly esoteric regular expression, which utilizes the C<(?{...})>
construct to insert matched parameters into the hash reference.

The special C<[% ... %]> directive is taken as the C</.*?/s> regex, i.e.
I<ignore everything (as short as possible) between this identifier and
the next one>.  For backward compatibility, C<[% _ %]> and C<[% __ %]>
are also accepted.

The special C<[% // %]> directive is taken as a non-capturing regex,
embedded inside C</(?:)/s>; for example, C<[% /\d*/ %]> matches any
number of digits.  Capturing parentheses may not be used with this
directive, but you can use the C<[% var =~ // %]> directive to capture
the match into C<var>.

You may set C<$Template::Extract::DEBUG> to a true value to display
generated regular expressions.

The extraction process defaults to succeed even with a partial match.
To match the entire document only, set C<$Template::Extract::EXACT> to
a true value.

=head2 compile($template)

Use B<Template::Extract::Compile> to perform the first phase of
C<extract>, by returning the regular expression compiled from
C<$template>.

=head2 run($regex, $document, \%values)

Use B<Template::Extract::Run> to perform the second phase of
C<extract>, by applying the regular expression on C<$document>
and returning the resulting C<\%values>.

=head1 SUBCLASSING

If you would like to use different modules to parse, compile and run
the extraction process, simply subclass C<Template::Extract> and
override the C<COMPILE_CLASS>, C<PARSER_CLASS> and C<RUN_CLASS>
methods to return alternate class names.

=head1 CAVEATS

Currently, the C<extract> method only supports C<[% GET %]>,
C<[% SET %]> and C<[% FOREACH %]> directives, because C<[% WHILE %]>,
C<[% CALL %]> and C<[% SWITCH %]> blocks are next to impossible to
extract correctly.

C<[% SET key = "value" %]> only works for simple scalar values.

Outermost C<[% FOREACH %]> blocks must match at least once in the
document, but inner ones may occur zero times.  This is to prevent
the regex optimizer from failing prematurely.

There is no support for different I<PRE_CHOMP> and I<POST_CHOMP> settings 
internally, so extraction could fail silently on extra linebreaks.

It is somewhat awkward to use global variables to control C<EXACT> and C<DEBUG>
behaviour; patches welcome to promote them into per-instance options.

=head1 NOTES

This module's companion class, B<Template::Generate>, is still in early
experimental stages; it can take data structures and rendered documents,
then automagically generates templates to do the transformation. If you are
into related research, please mail any ideas to me.

=head1 SEE ALSO

L<Template::Extract::Compile>, L<Template::Extract::Run>,
L<Template::Extract::Parser>

L<Template>, L<Template::Generate>

Simon Cozens's introduction to this module, in O'Reilly's I<Spidering Hacks>:
L<http://www.oreillynet.com/pub/a/javascript/excerpt/spiderhacks_chap01/index.html>

Mark Fowler's introduction to this module, in The 2003 Perl Advent Calendar:
L<http://perladvent.org/2003/5th/>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2002, 2003, 2004, 2005, 2007
by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Template-Extract>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Extract>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Template-Extract>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Template-Extract>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Template-Extract>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Template::Extract>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-template-extract at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Template-Extract>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/template-extract>

  git clone git://github.com/shlomif/template-extract.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/template-extract/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2003 by Audrey Tang.

This is free software, licensed under:

  The MIT (X11) License

=cut
