package Parse::Liberty::Simple;

use strict;
use warnings;

our $VERSION    = 0.13;

use Parse::Liberty;


sub new {
    my $class = shift;
    my $file = shift;

    my $parser = new Parse::Liberty (file=>$file);

    bless {}, $class;
    return $parser->library;
}


## $attr->value
## returns the value of an attribute
sub Parse::Liberty::Attribute::value {
    my $self = shift;
    return join ',', map {$_->value} $self->get_values;
}

## $group->name
## returns the name of a group
sub Parse::Liberty::Group::name {
    my $self = shift;
    return join ',', $self->get_names;
}


## $parser->cells[('name1', 'name2', ...)]
## returns the list of library-level cell-type group objects
sub Parse::Liberty::Group::cells {
    my $self = shift;
    my @names = @_;
    return undef if $self->type ne 'library';
    return $self->get_groups('cell', @names);
}


## $group->attrs[('name1', 'name2', ...)]
## returns the list of group-level attribute objects
sub Parse::Liberty::Group::attrs {
    my $self = shift;
    my @names = @_;
    return $self->get_attributes(@names);
}

## $group->attr('name')
## returns the _value_ of group-level attribute
sub Parse::Liberty::Group::attr {
    my $self = shift;
    my $name = shift;
    my $attr = $self->get_attributes($name);
    return (defined $attr) ? $attr->value : undef;
}

## $cell->pins[('name1', 'name2', ...)]
## returns the list of group-level pin-type group objects
sub Parse::Liberty::Group::pins {
    my $self = shift;
    my @names = @_;
    return undef if $self->type ne 'cell';
    return $self->get_groups('pin', @names);
}


1;
