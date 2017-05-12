package MooseX::MultiObject::Role;
BEGIN {
  $MooseX::MultiObject::Role::VERSION = '0.03';
}
# ABSTRACT: role that a MultiObject does
use Moose::Role;
use true;
use namespace::autoclean;

requires 'add_managed_object';
requires 'get_managed_objects';

__END__
=pod

=head1 NAME

MooseX::MultiObject::Role - role that a MultiObject does

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

