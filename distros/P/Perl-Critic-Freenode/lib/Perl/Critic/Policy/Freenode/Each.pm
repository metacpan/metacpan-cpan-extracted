package Perl::Critic::Policy::Freenode::Each;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.030';

use constant DESC => 'each() called';
use constant EXPL => 'The each function may cause undefined behavior when operating on the hash while iterating. Use a foreach loop over the hash\'s keys or values instead.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Word' }

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem eq 'each' and is_function_call $elem;
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::Each - Don't use each to iterate through a hash

=head1 DESCRIPTION

The C<each()> function relies on an iterator internal to a hash (or array),
which is the same iterator used by C<keys()> and C<values()>. So deleting or
adding hash elements during iteration, or just calling C<keys()> or C<values()>
on the hash, will cause undefined behavior and the code will likely break. This
could occur even by passing the hash to other functions which operate on the
hash. Instead, use a C<foreach> loop iterating through the keys or values of
the hash.

  while (my ($key, $value) = each %hash) { ... }                # not ok
  foreach my $key (keys %hash) { my $value = $hash{$key}; ... } # ok

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<http://blogs.perl.org/users/rurban/2014/04/do-not-use-each.html>
