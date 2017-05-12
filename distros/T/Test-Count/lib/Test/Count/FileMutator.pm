package Test::Count::FileMutator;

use warnings;
use strict;

use base 'Test::Count::Base';

use Test::Count;
use Test::Count::Lib;

=encoding utf8

=head1 NAME

Test::Count::FileMutator - modify a file in place

=cut

our $VERSION = '0.0901';

sub _counter
{
    my $self = shift;
    if (@_)
    {
        $self->{'_counter'} = shift;
    }
    return $self->{'_counter'};
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

sub _plan_prefix_regex
{
    my $self = shift;
    if (@_)
    {
        $self->{'_plan_prefix_regex'} = shift;
    }
    return $self->{'_plan_prefix_regex'};
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

=head2 my $filter = Test::Count::Filter->new({%args});

C<%args> may contain the following:

=over 4

=item * filename

The filename of the file to mutate.

=item * assert_prefix_regex

Passed to L<Test::Count>.

=item * plan_prefix_regex

The prefix regex for detecting a plan line: i.e: a line that specifies
how many tests to run. Followed immediately by a sequence of digits containing
the number of tests. The latter will be updated with the number of tests.

Can be a regex or a string.

=back

=cut

sub _init
{
    my $self = shift;
    my $args = shift;

    $args->{plan_prefix_regex} ||= Test::Count::Lib::perl_plan_prefix_regex();

    # Remmed out because Test::Count handles it by itself.
    # if (defined($args->{assert_prefix_regex}))
    # {
    #     $self->_assert_prefix_regex($args->{assert_prefix_regex});
    # }
    $self->_plan_prefix_regex($args->{plan_prefix_regex});
    $self->_filename($args->{filename});

    $self->_counter(Test::Count->new($args));

    return 0;
}

=head2 $filter->modify()

Modify the file in-place.

=cut

sub modify
{
    my $self = shift;

    my $ret = $self->_counter()->process();

    my $count = $ret->{tests_count};

    my $plan_re = $self->_plan_prefix_regex();

    my @lines = @{$ret->{lines}};

    open my $out_fh, ">", $self->_filename()
        or die "Could not open file '" . $self->_filename() . "' for writing - $!.";
    LINES_LOOP:
    while (my $l = shift(@lines))
    {
        if ($l =~
            s{^($plan_re)\d+}{$1$count}
           )
        {
            print {$out_fh} $l;
            last LINES_LOOP;
        }
        else
        {
            print {$out_fh} $l;
        }
    }
    print {$out_fh} @lines;

    close($out_fh);
    return 0;
}

=head1 SYNOPSIS

    use Test::Count::Parser;

    my $parser = Test::Count::Parser->new();

    $parser->update_assignments($string);

    $parser->update_count($string);

    my $value = $parser->get_count();

=head1 DESCRIPTION

After initiating a parser one can input assignment expressions, and count
update expressions. Both of them use arithmetic operations, integers, and
Perl-like variable names.

At the end one should call C<$parser->get_count()> in order to get the
total number of tests.

=head1 FUNCTIONS

=head2 $parser->update_assignments({'text' => $mytext,})

Updates the parser's state based on the assignments in C<$mytext>. For
example if C<$mytext> is:

     $myvar=500;$another_var=8+$myvar

Then at the end C<$myvar> would be 500 and C<$another_var> would be 508.

=cut

sub update_assignments
{
    my ($self, $args) = @_;

    return $self->_parser()->assignments($args->{text});
}

=head2 $parser->update_count({'text' => $mytext,})

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

=head1 SEE ALSO

L<Test::Count>, L<Test::Count::Parser>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish.

This program is released under the following license: MIT X11.

=cut

1; # End of Test::Count::Parser
