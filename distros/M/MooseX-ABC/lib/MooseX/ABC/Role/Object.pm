package MooseX::ABC::Role::Object;
BEGIN {
  $MooseX::ABC::Role::Object::AUTHORITY = 'cpan:DOY';
}
{
  $MooseX::ABC::Role::Object::VERSION = '0.06';
}
use Moose::Role;
# ABSTRACT: base object role for L<MooseX::ABC>


around new => sub {
    my $orig = shift;
    my $class = shift;
    my $meta = Class::MOP::class_of($class);
    $meta->throw_error("$class is abstract, it cannot be instantiated")
        if $meta->is_abstract;
    $class->$orig(@_);
};

no Moose::Role;

1;

__END__
=pod

=head1 NAME

MooseX::ABC::Role::Object - base object role for L<MooseX::ABC>

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This is a base object role implementing the behavior of L<MooseX::ABC> classes
being uninstantiable.

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

