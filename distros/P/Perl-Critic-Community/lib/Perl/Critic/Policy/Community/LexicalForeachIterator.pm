package Perl::Critic::Policy::Community::LexicalForeachIterator;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy::Variables::RequireLexicalLoopIterators';

our $VERSION = 'v1.0.4';

sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'community' }

1;

=head1 NAME

Perl::Critic::Policy::Community::LexicalForeachIterator - Don't use undeclared
foreach loop iterators

=head1 DESCRIPTION

It's possible to use a variable that's already been declared as the iterator
for a L<foreach loop|perlsyn/"Foreach Loops">, but this will localize the
variable to the loop and its value will be reverted after the loop is done.
Always declare the loop iterator in the lexical scope of the loop with C<my>.

 foreach $foo (...) {...}    # not ok
 for $bar (...) {...}        # not ok
 foreach my $foo (...) {...} # ok
 for my $bar (...) {...}     # ok

This policy is a subclass of the L<Perl::Critic> core policy
L<Perl::Critic::Policy::Variables::RequireLexicalLoopIterators>, and performs
the same function but in the C<community> theme.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Community>.

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
