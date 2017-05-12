package Spica::Receiver::Row;
use strict;
use warnings;
use utf8;

use Carp ();

use Mouse;

has data => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);
has select_columns => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        return [keys %{ shift->data }],
    },
);
has spica => (
    is  => 'ro',
    isa => 'Spica',
);
has client => (
    is      => 'ro',
    isa     => 'Spica::Client',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->spica->spec->get_client($self->client_name);
    },
);
has client_name => (
    is  => 'ro',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;

    # inflated values
    $self->{_get_column_cached} = +{};
    # values will be updated
    $self->{_autoload_column_cache} = +{};

    # hookpoint:
    #   name: `init_row_class`
    #   args: ($spica isa 'Spica', $data isa `HashRef`)
    $self->{data} = $self->client->call_filter(init_row_class => ($self->spica, $self->{data}));
}

no Mouse;

our $AUTOLOAD;

sub generate_column_accessor {
    my ($x, $column) = @_;

    return sub {
        my $self = shift;

        # getter is alias of get (inflate column)
        return $self->get($column);
    };
}

sub handle { $_[0]->spica }

sub get {
    my ($self, $column) = @_;

    # "Untrusted" means the row is set_column by scalarref
    if ($self->{_untrusted_data}{$column}) {
        Carp::carp("${column}'s row data is untrusted. by your update query.");
    }
    my $cache = $self->{_get_column_cached};
    my $data = $cache->{$column};

    unless ($data) {
        $data = $cache->{$column} = $self->client ?
            $self->client->call_inflate($column => $self->get_column($column)) :
            $self->get_column($column);
    }

    return $data;
}

sub get_column {
    my ($self, $column) = @_;

    unless ($column) {
        Carp::croak('Please specify $column for first argument.');
    }

    if (exists $self->{data}{$column}) {
        return $self->{data}{$column};
    } else {
        Carp::croak("Specified column '${column}'");
    }
}

sub get_columns {
    my $self = shift;

    my %data;
    for my $column (@{ $self->select_columns }) {
        $data{$column} = $self->get_column($column);
    }
    return \%data;
}

# for +columns option by some search methods
sub AUTOLOAD {
    my $self = shift;
    my ($method) = ($AUTOLOAD =~ /([^:']+$)/);
    ($self->{_autoload_column_cache}{$method} ||= $self->generate_column_accessor($method))->($self);
}

### don't autoload this
sub DESTROY { 1 };

1;
__END__

=encoding utf-8

=head1 NAME

Spica::Receiver::Row

=head1 SYNOPSIS

    my $spica = Spica->new(host => 'example.com');

    my $iterator = Spica->new(host => 'example.com')->fetch('/list', +{});

    while (my $row = $iterator->next) {

        say $row->column_name;
        say $row->get('column_name');

        say $row->get_column('column_name'); # not inflated data
        my $data = $row->get_columns; # not inflated by HashRef
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 Spica::Receiver::Row->new(%args)

arguments be:

=over

=item data

=item spica

=item client

=item client_name

=back

=head2 $row->get($column_name)

=head2 $row->get_column($column_name)

=head2 $row->get_columns

=cut
