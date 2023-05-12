package Protocol::FIX::BaseComposite;

use strict;
use warnings;

use Protocol::FIX;

our $VERSION = '0.08';    ## VERSION

=head1 NAME

Protocol::FIX::BaseComposite - base class for Component, Group and Message

=cut

=head1 METHODS (for protocol developers)

=head3 new

    new($class, $name, $type, $composites)

Creates new BaseComposite (performed by Protocol, when it parses XML definition)

=cut

sub new {
    my ($class, $name, $type, $composites) = @_;

    die "composites array must be even"
        if @$composites % 2;

    die "composites array must be non-empty"
        unless @$composites;

    die "composite name must be defined"
        if (!defined($name) || $name !~ /.+/);

    my @composites;
    my @mandatory_composites;
    my %composite_by_name;
    my %component_for;

    for (my $idx = 0; $idx < @$composites; $idx += 2) {
        my $c        = $composites->[$idx];
        my $required = $composites->[$idx + 1];
        die "The object $idx must be a composite"
            unless Protocol::FIX::is_composite($c);

        my $prerequisite_composite;
        if ($c->{type} eq 'DATA') {
            my $valid_definition = ($idx > 0)
                && $composites->[$idx - 2]->{type} eq 'LENGTH';
            die "The field type 'LENGTH' must appear before field " . $c->{name}
                unless $valid_definition;
            $prerequisite_composite = $composites->[$idx - 2];
        }

        push @composites,           $c, ($required ? 1 : 0);
        push @mandatory_composites, $c->{name} if $required;
        $composite_by_name{$c->{name}} = [$c, $prerequisite_composite];

        if (UNIVERSAL::isa($c, 'Protocol::FIX::Component')) {
            my $sub_dependency = $c->{field_to_component};
            for my $k (keys %$sub_dependency) {
                if (exists $component_for{$k}) {
                    die(      "Ambiguity when constructing component '$name': '$k' already points to '"
                            . $component_for{$k}
                            . "', trying to add another pointer to '"
                            . $sub_dependency->{$k}
                            . "'");
                }
                $component_for{$k} = $sub_dependency->{$k};
            }
        }
        if (exists $component_for{$c->{name}}) {
            die(      "Ambiguity when constructing component '$name': '"
                    . $c->{name}
                    . "' already points to '"
                    . $component_for{$c->{name}}
                    . "', trying to add another pointer to '"
                    . $name
                    . "'");
        }
        $component_for{$c->{name}} = $name;

    }

    my $obj = {
        name                 => $name,
        type                 => $type,
        composites           => \@composites,
        composite_by_name    => \%composite_by_name,
        mandatory_composites => \@mandatory_composites,
        field_to_component   => \%component_for,
    };

    return bless $obj, $class;
}

=head3 serialize

    serialize($self, $values)

Serializes array of C<$values>. Not for end-user usage. Please, refer
L<Message/"serialize">

=cut

sub serialize {
    my ($self, $values) = @_;

    die "values must be non-empty even array"
        if (ref($values) ne 'ARRAY') || !@$values || (@$values % 2);

    my @strings;

    my %used_composites;
    for (my $idx = 0; $idx < @$values; $idx += 2) {
        my $name   = $values->[$idx];
        my $value  = $values->[$idx + 1];
        my $c_info = $self->{composite_by_name}->{$name};
        if (!$c_info) {
            die "Composite '$name' is not available for " . $self->{type} . " '" . $self->{name} . "'";
        }

        my $c = $c_info->[0];
        if ($c->{type} eq 'DATA') {
            my $c_length       = $c_info->[1];
            my $valid_sequence = ($idx > 0)
                && $self->{composite_by_name}->{$values->[$idx - 2]}->[0] == $c_length;

            die "The field '" . $c_length->{name} . "' must precede '" . $c->{name} . "'"
                unless $valid_sequence;

            my $actual_length = length($value);
            die "The length field '" . $c_length->{name} . "' ($actual_length) isn't equal previously declared (" . $values->[$idx - 1] . ")"
                unless $values->[$idx - 1] == $actual_length;
        }

        push @strings, $c->serialize($value);
        $used_composites{$name} = 1;
    }
    for my $mandatory_name (@{$self->{mandatory_composites}}) {
        die "'$mandatory_name' is mandatory for " . $self->{type} . " '" . $self->{name} . "'"
            unless exists $used_composites{$mandatory_name};
    }
    return join $Protocol::FIX::SEPARATOR, @strings;
}

1;
