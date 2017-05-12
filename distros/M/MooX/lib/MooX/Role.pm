package MooX::Role;
BEGIN {
  $MooX::Role::AUTHORITY = 'cpan:GETTY';
}
{
  $MooX::Role::VERSION = '0.101';
}
# ABSTRACT: Using Moo::Role and MooX:: packages the most lazy way

use strict;
use warnings;
use MooX ();

sub import {
	my ( $class, @modules ) = @_;
	my $target = caller;
	unshift @modules, '+Moo::Role';
  MooX::import_base($class,$target,@modules);
}

1;


__END__
=pod

=head1 NAME

MooX::Role - Using Moo::Role and MooX:: packages the most lazy way

=head1 VERSION

version 0.101

=head1 SYNOPSIS

  package MyRole;

  use MooX::Role qw(
    Options
  );

  # use Moo::Role;
  # use MooX::Options;

=head1 DESCRIPTION

Exactly the same behaviour as L<MooX>, but instead importing L<Moo>, it imports L<Moo::Role>.

=encoding utf8

=head1 SEE ALSO

=head2 L<Role::Tiny>

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-moox
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-moox/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

