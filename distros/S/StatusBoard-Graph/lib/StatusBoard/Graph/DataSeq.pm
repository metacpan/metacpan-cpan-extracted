package StatusBoard::Graph::DataSeq;
{
  $StatusBoard::Graph::DataSeq::VERSION = '1.0.1';
}

# ABSTRACT: datasequences representation for the StatusBoard::Graph


use strict;
use warnings;
use utf8;

use Carp;

my $true = 1;
my $false = '';


sub new {
    my ($class, %opts) = @_;

    croak "Constructor new() does not need any parameters." if %opts;

    my $self = {};
    bless $self, $class;

    return $self;
}


sub set_title {
    my ($self, $title) = @_;

    $self->{__title} = $title;

    return $false;
}


sub get_title {
    my ($self) = @_;

    croak "No title. Stopped" if not defined $self->{__title};

    return $self->{__title};
}


sub set_color {
    my ($self, $color) = @_;

    $self->{__color} = $color;

    return $false;
}


sub has_color {
    my ($self) = @_;

    return defined($self->{__color}) ? $true : $false;
}


sub get_color {
    my ($self) = @_;

    croak "No color. Stopped" if not $self->has_color();

    return $self->{__color};
}


sub set_values {
    my ($self, $values) = @_;

    if (ref $values ne 'ARRAY') {
        croak "Incorrect values. Stopped";
    }

    $self->{__values} = $values;

    return $false;
}


sub get_values {
    my ($self) = @_;

    my $v = $self->{__values};

    if (not defined $v) {
        croak "No values in StatusBoard::Graph::DataSeq. Stopped";
    }

    return $self->{__values};
}


1;

__END__

=pod

=head1 NAME

StatusBoard::Graph::DataSeq - datasequences representation for the StatusBoard::Graph

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use StatusBoard::Graph::DataSeq;

    my $ds = StatusBoard::Graph::DataSeq->new();
    $ds->set_title("X-Cola");
    $ds->set_values(
        [
            2008 => 22,
            2009 => 24,
            2010 => 25.5,
            2011 => 27.9,
            2012 => 31,
        ]
    );

=head1 DESCRIPTION

This is and class StatusBoard::Graph::DataSeq that is used in
StatusBoard::Graph.

=head1 METHODS

=head2 new

This a constuctor. It creates StatusBoard::Graph object. It don't need any
parameters.

    my $ds = StatusBoard::Graph::DataSeq->new();

=head2 set_title

Sets title for the datasequences. This parameter is mandatory.

    $ds->set_title("X-Cola");

=head2 get_title

Returns the title of the object or dies if there is no title.

=head2 set_color

Sets the color for the datasequence. Color values can be yellow, green, red,
purple, blue, mediumGray, pink, aqua, orange, or lightGray.

If the color is not set then StatusBoard App will choose the color randomly.

=head2 has_color

Returns bool value if the color is set.

=head2 get_color

Returns the color or dies if no color is set.

=head2 set_values

Sets the values for the datasequence. The method shuold recieve arrayref with
pairs of values. First element in the pair will be used for the title and the
second will be used for the value.

    $ds->set_values(
        [
            2008 => 22,
            2009 => 24,
            2010 => 25.5,
            2011 => 27.9,
            2012 => 31,
        ]
    );

=head2 get_values

Returns the values or dies if there are no values.

=head1 TODO

Several move things should be done.

=over

=item * Check that color is one of yellow, green, red, purple, blue,
mediumGray, pink, aqua, orange, or lightGray

=item * Die if the title is not set

=item * has_values()

=back

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
