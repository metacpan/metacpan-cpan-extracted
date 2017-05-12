package Test::Count::Parser;

use warnings;
use strict;

use base 'Test::Count::Base';

use File::Basename (qw(dirname));

use Parse::RecDescent;

=encoding utf8

=head1 NAME

Test::Count::Parser - A Parser for Test::Count.

=cut

our $VERSION = '0.0901';

sub _get_grammar
{
    return <<'EOF';
update_count: expression            {$thisparser->{count} += $item[1]}

assignments:    statement <commit> ';' assignments
              | statement

statement:    assignment
              | expression               {$item [1]}
              | including_file           {$item [1]}

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

    my $parser = Parse::RecDescent->new($self->_get_grammar());

    $parser->{vars} = {};
    $parser->{count} = 0;
    $parser->{includes} = [];

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

    $self->_current_fns([]);
    $self->_parser($self->_calc_parser());

    return 0;
}

=head1 SYNOPSIS

    use Test::Count::Parser;

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

=cut

sub _push_current_filename
{
    my $self = shift;
    my $filename = shift;

    push @{$self->_current_fns()}, $filename;

    return;
}

sub _pop_current_filenames
{
    my $self = shift;
    my $filename = shift;

    pop(@{$self->_current_fns()});

    return;
}

sub _get_current_filename
{
    my $self = shift;

    return $self->_current_fns->[-1];
}

sub _parse_filename
{
    my $self = shift;
    my $filename = shift;

    $filename =~ s{\A"}{};
    $filename =~ s{"\z}{};

    my $dirname = dirname($self->_get_current_filename());
    $filename =~ s{\$\^CURRENT_DIRNAME}{$dirname}g;

    return $filename;
}

sub update_assignments
{
    my ($self, $args) = @_;

    $self->_parser->{includes} = [];
    my $ret = $self->_parser()->assignments($args->{text});

    if (@{$self->_parser->{includes}})
    {
        foreach my $include_file (@{$self->_parser->{includes}})
        {
            my $counter =
                Test::Count->new(
                    {
                        filename => $self->_parse_filename($include_file),
                    },
                );
            $counter->process({parser => $self});
        }
        $self->_parser->{includes} = [];
    }
}

=head2 $parser->update_count({'text' => $mytext,)

Adds the expression inside C<$mytext> to the internal counter of the
module. This is in order to count the tests.

=cut

sub update_count
{
    my ($self, $args) = @_;

    return $self->_parser()->update_count($args->{text});
}

=head2 my $count = $parser->get_count()

Get the total number of tests in the parser.

=cut

sub get_count
{
    my $self = shift;

    return $self->_parser()->{count};
}

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

The Parser uses L<Parse::RecDescent> by Damian Conway and is based on the
example code of René Nyffenegger (L<http://www.adp-gmbh.ch/>) available here:

L<http://www.adp-gmbh.ch/perl/rec_descent.html>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish.

This program is released under the following license: MIT X11.

=cut

1; # End of Test::Count::Parser
