package MooseX::Params::Meta::TypeConstraint::Listable;
{
  $MooseX::Params::Meta::TypeConstraint::Listable::VERSION = '0.010';
}

use strict;
use warnings;

use Moose;
BEGIN { extends 'Moose::Meta::TypeConstraint::Parameterizable' }

__PACKAGE__->meta->add_attribute('listable' => (
    reader => 'listable',
));

1;

__END__
=pod

=for :stopwords Peter Shangov TODO invocant isa metaroles metarole multimethods sourcecode
backwards buildargs checkargs slurpy preprocess

=head1 NAME

MooseX::Params::Meta::TypeConstraint::Listable

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Peter Shangov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

