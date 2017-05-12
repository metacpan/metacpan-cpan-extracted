package MooseX::MultiObject::Meta::Class;
BEGIN {
  $MooseX::MultiObject::Meta::Class::VERSION = '0.03';
}
# ABSTRACT: metarole for MultiObject metaclass
use Moose::Role;
use true;
use namespace::autoclean;

has 'set_attribute_name' => (
    reader    => 'get_set_attribute_name',
    writer    => 'set_set_attribute_name',
    predicate => 'has_set_attribute_name',
    isa       => 'Str',
);

__END__
=pod

=head1 NAME

MooseX::MultiObject::Meta::Class - metarole for MultiObject metaclass

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

