package TPath::Forester::Ref::Expression;
{
  $TPath::Forester::Ref::Expression::VERSION = '0.004';
}

# ABSTRACT: expression that converts a ref into a L<TPath::Forester::Ref::Root> before walking it


use Moose;
use namespace::autoclean;

extends 'TPath::Expression';


sub dsel {
    my ( $self, $node ) = @_;
    my @selection = $self->select($node);
    return $selection[0] unless wantarray;
    map { $_->value } $self->select($node);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

TPath::Forester::Ref::Expression - expression that converts a ref into a L<TPath::Forester::Ref::Root> before walking it

=head1 VERSION

version 0.004

=head1 DESCRIPTION

A L<TPath::Expression> that provides the C<dsel> method.

=head1 METHODS

=head2 dsel

"De-references" the values selected by the path, extracting them from the
L<TPath::Forester::Ref::Node> objects that hold them.

In an array context C<dsel> returns all selections. Otherwise, it returns
the first node selected.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
