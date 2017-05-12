package Scrappy::Project::Document;

BEGIN {
    $Scrappy::Project::Document::VERSION = '0.94112090';
}

use Moose::Role;

has fields => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my $self = shift;

        #die Data::Dumper::Dumper((shift->meta->get_all_methods)[1]);

        my @fields = ();
        for ($self->meta->get_all_methods) {
            push @fields, $_->name
              if $_->package_name eq ref $self
                  && $_->name ne 'meta'
                  && $_->name ne 'scraper'
                  && $_->name ne 'fields'
                  && $_->name ne 'parse'
                  && $_->name ne 'records'
                  && $_->name ne 'url';

            ##### NOTE !!!!!! The list above must always contain a list
            ##### of all attributes and function in this role
        }

        return [@fields];
    }
);

has records => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] }
);

has scraper => (
    is  => 'rw',
    isa => 'Scrappy'
);

sub parse {
    my ($self, $vars) = @_;

    my $record = {};
    map { $record->{$_} = $self->$_($self->scraper, $vars) } @{$self->fields};

    # $record->{url} = $self->scraper->url->as_string;
    push @{$self->records}, $record;

    return $record;
}

1;
