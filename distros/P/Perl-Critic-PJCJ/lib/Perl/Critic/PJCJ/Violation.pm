package Perl::Critic::PJCJ::Violation v0.3.0;

use v5.26.0;
use strict;
use warnings;
use feature      qw( signatures );
use experimental qw( signatures );

use parent qw( Perl::Critic::Violation );

sub set_fix ($self, $fix) {
  $self->{_pjcj_fix} = $fix;
  $self
}

sub fix ($self) { $self->{_pjcj_fix} }

"
Just close your eyes again
Until these things get better
You're never far away
But we could send letters
"

__END__

=pod

=head1 NAME

Perl::Critic::PJCJ::Violation - a violation that carries its own fix

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

  my $violation = Perl::Critic::PJCJ::Violation
    ->new($description, $explanation, $elem, $severity)
    ->set_fix({ type => "double" });

  my $fix = $violation->fix;

=head1 DESCRIPTION

A subclass of L<Perl::Critic::Violation> that lets a policy attach the
structured fix data describing how to resolve the violation. The
L<Perl::Critic::PJCJ::Fixer> reads C<fix> directly instead of looking the fix
up again by the rendered description string.

The inherited constructor is used unchanged: it records the calling package as
the violation's policy, so the subclass must be instantiated from within the
policy package.

=head1 METHODS

=head2 set_fix ($fix)

Attach the fix structure to the violation and return the violation, so the
call can be chained after C<new>.

=head2 fix

Return the attached fix structure, or C<undef> if none was set.

=head1 AUTHOR

Paul Johnson <paul@pjcj.net>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
