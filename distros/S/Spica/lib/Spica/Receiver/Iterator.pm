package Spica::Receiver::Iterator;
use strict;
use warnings;
use 5.10.0;

use Mouse;

has spica => (
    is  => 'ro',
    isa => 'Spica',
);
has row_class => (
    is  => 'ro',
    isa => 'ClassName',
);
has client => (
    is  => 'ro',
    isa => 'Spica::Client',
);
has client_name => (
    is  => 'ro',
    isa => 'Str',
);
has suppress_object_creation => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);
has data => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

has position => (
    is       => 'ro',
    isa      => 'Int',
    required => 0,
    default  => 0,
);

around BUILDARGS => sub {
    my $origin = shift;
    my $class  = shift;
    my %args = @_;

    if (!$args{data}) {
        $args{data} = [];
    } elsif (ref $args{data} eq 'HASH') {
        $args{data} = [$args{data}];
    }

    return $class->$origin(%args);
};

no Mouse;

sub next {
    my $self = shift;

    my $row = $self->{data}[$self->{position}++];

    unless ($row) {
        $self->{position} = 0;
        return;
    }

    if ($self->{suppress_object_creation}) {
        return $row;
    } else {
        return $self->{row_class}->new(
            data           => $row,
            spica          => $self->spica,
            client         => $self->client,
            client_name    => $self->client_name,
            select_columns => $self->{select_columns} || [],
        );
    }
}

sub all {
    my $self = shift;

    my $results = [];

    if ($self->{data}) {
        $results = $self->{data};

        if (!$self->{suppress_object_creation}) {
            $results = [
                map {
                    $self->row_class->new(
                        data           => $_,
                        spica          => $self->spica,
                        client         => $self->client,
                        client_name    => $self->client_name,
                        select_columns => $self->{select_columns} || [],
                    )
                } @$results
            ];
        }
    }

    return wantarray ? @$results : $results;
}

1;
__END__

=encoding utf-8

=head1 NAME

Spica::Receiver::Iterator

=head1 SYNOPSIS

    my $spica = Spica->new(host => 'example.com');

    my $iterator = Spica->new(host => 'example.com')->fetch('/list', +{});

    while (my $row = $iterator->next) {
        ...
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 Spica::Receiver::Iterator->new(%args)

arguments be:

=over

=item data

=item spica

=item row_class

=item client

=item client_name

=item suppress_object_creation

=back

=head2 $iterator->next

=head2 $iterator->all

=head2 $iterator->suppress_object_creation

=cut
