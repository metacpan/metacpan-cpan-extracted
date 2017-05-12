package TPath::Forester::File::Index;
{
  $TPath::Forester::File::Index::VERSION = '0.003';
}

# ABSTRACT: index used by L<TPath::Forester::File>


use Moose;

extends 'TPath::Index';

sub is_root { $_[1]->is_root }

sub index { }

sub parent { $_[1]->parent }

sub id { }

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

TPath::Forester::File::Index - index used by L<TPath::Forester::File>

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Since L<TPath::Forester::File::Node> objects know their own parents, this index
mostly just delegates to their methods.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
