package Net::GraphSpace::AttributesToJSON;
use Moose::Role;
use v5.10;

sub TO_JSON {
    my ($self) = @_;
    my @attrs = $self->meta->get_all_attributes;
    return { map $self->_affinitize($_), @attrs };
}

sub _affinitize {
    my ($self, $attr) = @_;
    my $name = $attr->name;
    my $value = $self->$name;
    return if not defined $value;
    given ($attr->type_constraint) {
        when ($_->equals('Str')) { "$value"   }
        when ($_->equals('Int')) { int $value }
    }
    return $name => $value;
}

1;

__END__
=pod

=head1 NAME

Net::GraphSpace::AttributesToJSON

=head1 VERSION

version 0.0009

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

