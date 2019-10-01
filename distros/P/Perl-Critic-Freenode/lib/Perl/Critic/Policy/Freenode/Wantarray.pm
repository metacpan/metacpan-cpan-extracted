package Perl::Critic::Policy::Freenode::Wantarray;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.031';

use constant DESC => 'wantarray() called';
use constant EXPL => 'Context-sensitive functions lead to unexpected errors or vulnerabilities. Functions should explicitly return either a list or a scalar value.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Word' }

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem eq 'wantarray' and is_function_call $elem;
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::Wantarray - Don't write context-sensitive
functions using wantarray

=head1 DESCRIPTION

Context-sensitive functions, while one way to write functions that DWIM (Do
What I Mean), tend to instead lead to unexpected behavior when the function is
accidentally used in a different context, especially if the function's behavior
changes significantly based on context. This also can lead to vulnerabilities
when a function is intended to be used as a scalar, but is used in a list, such
as a hash constructor or function parameter list. Instead, functions should be
explicitly documented to return either a scalar value or a list, so there is no
potential for confusion or vulnerability.

  return wantarray ? ('a','b','c') : 3; # not ok
  return ('a','b','c');                 # ok
  return 3;                             # ok

  sub get_stuff {
    return wantarray ? @things : \@things;
  }
  my $stuff = Stuff->new(stuff => get_stuff()); # oops! function will return a list!

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
