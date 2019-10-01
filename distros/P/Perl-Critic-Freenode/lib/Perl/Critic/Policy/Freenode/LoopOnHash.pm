package Perl::Critic::Policy::Freenode::LoopOnHash;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy::Variables::ProhibitLoopOnHash';

our $VERSION = '0.031';

sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::LoopOnHash - Don't loop over hashes

=head1 DESCRIPTION

It's possible to loop over a hash as if it was a list, which results in
alternating between the keys and values of the hash. Often, the intent was
instead to loop over either the keys or the values of the hash.

 foreach my $foo (%hash) { ... }      # not ok
 action() for %hash;                  # not ok
 foreach my $foo (keys %hash) { ... } # ok
 action() for values %hash;           # ok

If you intended to loop over alternating keys and values, you can make this
intent clear by first copying them to an array:

 foreach my $key_or_value (@{[%hash]}) { ... }
 foreach my $key_or_value (my @dummy = %hash) { ... }

This policy is a subclass of the policy
L<Perl::Critic::Policy::Variables::ProhibitLoopOnHash>, and performs the same
function but in the C<freenode> theme.

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

L<Perl::Critic>
