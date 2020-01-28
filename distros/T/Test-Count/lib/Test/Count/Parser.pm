package Test::Count::Parser;
$Test::Count::Parser::VERSION = '0.1102';
use warnings;
use strict;

use parent 'Test::Count::Base';

use File::Basename (qw(dirname));

use Parse::RecDescent ();


sub _get_grammar
{
    return <<'EOF';
update_count: expression            {$thisparser->{count} += $item[1] * $thisparser->{filter_mults}->[-1]}

assignments:    statement <commit> ';' assignments
              | statement

statement:    assignment
              | expression               {$item [1]}
              | including_file           {$item [1]}
              | start_filter
              | end_filter

start_filter: 'FILTER(MULT(' expression '))' {push @{$thisparser->{filter_mults}}, $thisparser->{filter_mults}->[-1] * $item[2] ; }

end_filter: 'ENDFILTER()' {if (@{$thisparser->{filter_mults}} <= 1) { die "Too many ENDFILTER()s"; } pop @{$thisparser->{filter_mults}}; }

including_file: 'source' string          {push @{$thisparser->{includes}}, $item[2];}

assignment:    variable '=' statement   {$thisparser->{vars}->{$item [1]} = $item [3]}
              | variable '+=' statement   {$thisparser->{vars}->{$item [1]} += $item [3]}
              | variable '-=' statement   {$thisparser->{vars}->{$item [1]} -= $item [3]}
              | variable '*=' statement   {$thisparser->{vars}->{$item [1]} *= $item [3]}

expression:     variable '++'            {$thisparser->{vars}->{$item [1]}++}
              | term '+' expression      {$item [1] + $item [3]}
              | term '-' expression      {$item [1] - $item [3]}
              | term

term:           factor '*' term          {$item [1] * $item [3]}
              | factor '/' term          {int($item [1] / $item [3])}
              | factor

factor:         number
              | variable                 {
                (exists($thisparser->{vars}->{$item [1]})
                    ? $thisparser->{vars}->{$item [1]}
                    : do { die "Undefined variable \"$item[1]\""; } )
                    }
              | '+' factor               {$item [2]}
              | '-' factor               {$item [2] * -1}
              | '(' statement ')'        {$item [2]}

number:         /\d+/                    {$item [1]}

variable:       /\$[a-z_]\w*/i

string:         /"[^"]+"/

EOF
}

sub _calc_parser
{
    my $self = shift;

    my $parser = Parse::RecDescent->new( $self->_get_grammar() );

    $parser->{vars}         = {};
    $parser->{count}        = 0;
    $parser->{includes}     = [];
    $parser->{filter_mults} = [1];

    return $parser;
}

sub _parser
{
    my $self = shift;
    if (@_)
    {
        $self->{'_parser'} = shift;
    }
    return $self->{'_parser'};
}

sub _current_fns
{
    my $self = shift;
    if (@_)
    {
        $self->{'_current_fns'} = shift;
    }
    return $self->{'_current_fns'};
}

sub _init
{
    my $self = shift;

    $self->_current_fns( [] );
    $self->_parser( $self->_calc_parser() );

    return 0;
}


sub _push_current_filename
{
    my $self     = shift;
    my $filename = shift;

    push @{ $self->_current_fns() }, $filename;

    return;
}

sub _pop_current_filenames
{
    my $self     = shift;
    my $filename = shift;

    pop( @{ $self->_current_fns() } );

    return;
}

sub _get_current_filename
{
    my $self = shift;

    return $self->_current_fns->[-1];
}

sub _parse_filename
{
    my $self     = shift;
    my $filename = shift;

    $filename =~ s{\A"}{};
    $filename =~ s{"\z}{};

    my $dirname = dirname( $self->_get_current_filename() );
    $filename =~ s{\$\^CURRENT_DIRNAME}{$dirname}g;

    return $filename;
}

sub update_assignments
{
    my ( $self, $args ) = @_;

    $self->_parser->{includes} = [];
    my $ret = $self->_parser()->assignments( $args->{text} );

    if ( @{ $self->_parser->{includes} } )
    {
        foreach my $include_file ( @{ $self->_parser->{includes} } )
        {
            my $counter = Test::Count->new(
                {
                    filename => $self->_parse_filename($include_file),
                },
            );
            $counter->process( { parser => $self } );
        }
        $self->_parser->{includes} = [];
    }
}


sub update_count
{
    my ( $self, $args ) = @_;

    return $self->_parser()->update_count( $args->{text} );
}


sub get_count
{
    my $self = shift;

    return $self->_parser()->{count};
}


1;    # End of Test::Count::Parser

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Count::Parser - A Parser for Test::Count.

=head1 VERSION

version 0.1102

=head1 SYNOPSIS

    use Test::Count::Parser ();

    my $parser = Test::Count::Parser->new();

    $parser->update_assignments($string);

    $parser->update_count($string);

    my $value = $parser->get_count();

=head1 DESCRIPTIONS

After initiating a parser one can input assignment expressions, and count
update experssions. Both of them use arithmetic operations, integers, and
Perl-like variable names.

At the end one should call C<$parser->get_count()> in order to get the
total number of tests.

=head1 FUNCTIONS

=head2 $parser->update_assignments({'text' => $mytext,)

Updates the parser's state based on the assignments in C<$mytext>. For
example if C<$mytext> is:

     $myvar=500;$another_var=8+$myvar

Then at the end C<$myvar> would be 500 and C<$another_var> would be 508.

=head2 $parser->update_count({'text' => $mytext,)

Adds the expression inside C<$mytext> to the internal counter of the
module. This is in order to count the tests.

=head2 my $count = $parser->get_count()

Get the total number of tests in the parser.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-count-parser at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Count>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Count

You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Count>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Count>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Count>

=back

=head1 ACKNOWLEDGEMENTS

The Parser uses L<Parse::RecDescent> by Damian Conway and is based on the
example code of René Nyffenegger (L<http://www.adp-gmbh.ch/>) available here:

L<http://www.adp-gmbh.ch/perl/rec_descent.html>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish.

This program is released under the following license: MIT X11.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

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

L<https://github.com/shlomif/perl-test-count>

  git clone git://github.com/shlomif/perl-test-count.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-test-count/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
