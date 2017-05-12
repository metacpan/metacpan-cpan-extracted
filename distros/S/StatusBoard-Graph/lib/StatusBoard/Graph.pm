package StatusBoard::Graph;
{
  $StatusBoard::Graph::VERSION = '1.0.1';
}

# ABSTRACT: create JSON with graph data for Status Board iPad App


use strict;
use warnings;
use utf8;

use Carp;
use JSON;
use File::Slurp;
use Clone qw(clone);

my $true = 1;
my $false = '';


sub new {
    my ($class, %opts) = @_;

    croak "Constructor new() does not need any parameters." if %opts;

    my $self = {};
    bless $self, $class;

    return $self;
}


sub get_json {
    my ($self) = @_;

    my $json = to_json(
        $self->__get_data()
    );

    return $json;
}


sub get_pretty_json {
    my ($self) = @_;

    my $pretty_json = to_json(
        $self->__get_data(),
        {
            pretty => 1,
        },
    );

    return $pretty_json;
}


sub write_json {
    my ($self, $file_name) = @_;

    write_file(
        $file_name,
        {binmode => ':utf8'},
        $self->get_json(),
    );

    return $false;
}


sub set_title {
    my ($self, $title) = @_;

    $self->{__title} = $title;

    return $false;
}


sub has_title {
    my ($self) = @_;

    return defined($self->{__title}) ? $true : $false;
}


sub get_title {
    my ($self) = @_;

    croak "No title. Stopped" if not $self->has_title();

    return $self->{__title};
}


sub set_type {
    my ($self, $type) = @_;

    $self->{__type} = $type;

    return $false;
}


sub has_type {
    my ($self) = @_;

    return defined($self->{__type}) ? $true : $false;
}


sub get_type {
    my ($self) = @_;

    croak "No type. Stopped" if not $self->has_type();

    return $self->{__type};
}


sub add_data_seq {
    my ($self, $data_seq) = @_;

    push @{$self->{__data_seqs}}, $data_seq;

    return $false;
}


sub set_min_y_value {
    my ($self, $number) = @_;

    $self->{__min_y_value} = $number;

    return $false;
}


sub has_min_y_value {
    my ($self) = @_;

    return defined($self->{__min_y_value}) ? $true : $false;
}


sub get_min_y_value {
    my ($self) = @_;

    croak "No min y value. Stopped" if not $self->has_min_y_value();

    return $self->{__min_y_value};
}


sub set_max_y_value {
    my ($self, $number) = @_;

    $self->{__max_y_value} = $number;

    return $false;
}


sub has_max_y_value {
    my ($self) = @_;

    return defined($self->{__max_y_value}) ? $true : $false;
}


sub get_max_y_value {
    my ($self) = @_;

    croak "No max y value. Stopped" if not $self->has_max_y_value();

    return $self->{__max_y_value};
}

sub __get_data {
    my ($self) = @_;

    my $data = {
        graph => {
            title => $self->{__title},
            ( $self->has_type() ? ( type => $self->get_type() ) : () ),
            datasequences => $self->__get_datasequences(),
        }
    };

    if ($self->has_min_y_value()) {
        $data->{graph}->{yAxis}->{minValue} = $self->get_min_y_value() + 0;
    }

    if ($self->has_max_y_value()) {
        $data->{graph}->{yAxis}->{maxValue} = $self->get_max_y_value() + 0;
    }

    return $data;
}

sub __get_datasequences {
    my ($self) = @_;

    my $datasequences = [];

    foreach my $ds (@{$self->{__data_seqs}}) {
        my $values = clone $ds->get_values();

        my $datapoints;
        while (@{$values}) {
            my $title = shift @{$values};
            my $value = shift @{$values};
            push @{$datapoints}, {
                title => $title . "",
                value => $value,
            };
        }

        push @{$datasequences}, {
            title => $ds->{__title},
            ( $ds->has_color ? ( color => $ds->get_color() ) : ()  ),
            datapoints => $datapoints,
        };
    }

    return $datasequences;
}


1;

__END__

=pod

=head1 NAME

StatusBoard::Graph - create JSON with graph data for Status Board iPad App

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use StatusBoard::Graph;
    use StatusBoard::Graph::DataSeq;

    my $sg = StatusBoard::Graph->new();
    $sg->set_title("Soft Drink Sales");

    my $ds1 = StatusBoard::Graph::DataSeq->new();
    $ds1->set_title("X-Cola");
    $ds1->set_values(
        [
            2008 => 22,
            2009 => 24,
            2010 => 25.5,
            2011 => 27.9,
            2012 => 31,
        ]
    );
    $sg->add_data_seq($ds1);

    my $ds2 = StatusBoard::Graph::DataSeq->new();
    $ds2->set_title("Y-Cola");
    $ds2->set_values(
        [
            2008 => 18.4,
            2009 => 20.1,
            2010 => 24.8,
            2011 => 26.1,
            2012 => 29,
        ]
    );
    $sg->add_data_seq($ds2);

    $sg->write_json("cola.json");

Here is L<the screenshot|http://upload.bessarabov.ru/bessarabov/031VBX4pHw_ALPcxRTVjflnAWuc.png>
of how this JSON file looks in the Status Board App.

=head1 DESCRIPTION

There is a great iPad App called Status Board
L<http://www.panic.com/statusboard/>. It can show differect types of
information. One type is a Graph. To create that Graph one can use CSV format,
or use more powerfull JSON format.

This module simplifies the process of creation JSONs for Status Board App.
Here is the specification of JSON format:
L<http://www.panic.com/statusboard/docs/graph_tutorial.pdf>

StatusBoard::Graph version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=head1 METHODS

=head2 new

This a constuctor. It creates StatusBoard::Graph object. It don't need any
parameters.

    my $sg = StatusBoard::Graph->new();

=head2 get_json

Method generate and return JSON with Graph data that Status Board App can use.

    my $json = $sg->get_json();

=head2 get_pretty_json

The same as get_json(), but it returs JSON with identation. This method is not
recommened to use in production code, because JSON file with pretty JSON
weights more thatn JSON written in one line.

    my $json = $sg->get_pretty_json();

=head2 write_json

Writes JSON with Graph data to file. It writes JSON data that is generated
with get_json() method. There is no write_pretty_json() method.

    my $file_name = 'population.json';
    $sg->write_json($file_name);

=head2 set_title

Sets title for the Graph. On the same Graph there can be several
datasequences. To set the title for for special datasequences use method
set_title() in StatusBoard::Graph::DataSeq object.

    $sg->set_title("Soft Drink Sales");

=head2 has_title

Methods checks if the StatusBoard::Graph object has title (It has if the
method set_title has been executed).

=head2 get_title

Returns the title of StatusBoard::Graph object or dies if there is no title.

=head2 set_type

Sets the type of Graph. In can be "bar" or "line". Setting the type is
optional. If the type is not set then the Status Board will choose the type
automaticly (depending on the graph size).

    $sg->set_type("bar");

=head2 has_type

Returns bool value if the type is set.

=head2 get_type

Returns the Graph type or dies if the type is not set.

=head2 add_data_seq

StatusBoard App can show several different datasequences on the same Graph.
To show all that data you need to create StatusBoard::Graph::DataSeq object
and to attach it to StatusBoard::Graph object.

    my $ds1 = StatusBoard::Graph::DataSeq->new();
    $ds1->set_title("X-Cola");
    $ds1->set_values(
        [
            2008 => 22,
            2009 => 24,
        ]
    );

    $sg->add_data_seq($ds1);

=head2 set_min_y_value

StatusBoard gives the ability to scale the Graph. You can specify the Y-axis
to start at a particular value.

    $sg->set_min_y_value('78');

=head2 has_min_y_value

Returns bool value if the minimum Y-axis value is set.

=head2 get_min_y_value

Returns the mimimum Y-axis value or dies if it is not set.

=head2 set_max_y_value

You can specify the Y-axis to end at a particular value.

    $sg->set_max_y_value('84');

=head2 has_max_y_value

Returns bool value if the maximum Y-axis value is set.

=head2 get_max_y_value

Returns the maximum Y-axis value or dies if it is not set.

=head1 TODO

Several move things should be implemented.

=over

=item * refreshEveryNSeconds

=item * total

=item * units

=item * Hiding Axis Labels

=item * showEveryLabel

=item * Error Reporting

=item * set_type() should recieve only "bar" or "line"

=back

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
