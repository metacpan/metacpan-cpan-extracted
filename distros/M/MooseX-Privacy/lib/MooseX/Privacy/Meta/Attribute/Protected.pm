package MooseX::Privacy::Meta::Attribute::Protected;
BEGIN {
  $MooseX::Privacy::Meta::Attribute::Protected::VERSION = '0.05';
}

use Moose::Role;
use Carp qw/confess/;

with 'MooseX::Privacy::Meta::Attribute::Privacy' => {level => 'protected'};

sub _check_protected {
    my ($meta, $caller, $attr_name, $package_name, $object_name) = @_;
    confess "Attribute " . $attr_name . " is protected"
      unless $caller eq $object_name
          or $caller->isa($package_name);
}

1;

__END__
=pod

=head1 NAME

MooseX::Privacy::Meta::Attribute::Protected

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

