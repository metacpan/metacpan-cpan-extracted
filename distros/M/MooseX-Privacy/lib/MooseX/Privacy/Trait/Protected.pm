package MooseX::Privacy::Trait::Protected;
BEGIN {
  $MooseX::Privacy::Trait::Protected::VERSION = '0.05';
}

use Moose::Role;
with 'MooseX::Privacy::Trait::Role' => {name => 'Protected'};

1;

__END__
=pod

=head1 NAME

MooseX::Privacy::Trait::Protected

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

