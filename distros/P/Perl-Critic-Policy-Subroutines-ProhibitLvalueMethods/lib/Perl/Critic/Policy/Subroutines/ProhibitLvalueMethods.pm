package Perl::Critic::Policy::Subroutines::ProhibitLvalueMethods;
use strict;
use warnings;

our $VERSION = '0.001000';
$VERSION =~ tr/_//d;

use parent qw(Perl::Critic::Policy);

use Perl::Critic::Utils qw(
  is_method_call
  precedence_of
);

sub supported_parameters { }

sub default_severity     { return $Perl::Critic::Utils::SEVERITY_MEDIUM }
sub default_themes       { return qw( ) }

sub applies_to           { return 'PPI::Token::Word' }

# match by precedence to catch other assignment ops, like ||=
use constant ASSIGNMENT_PRECEDENCE => precedence_of('=');

my $DESC = 'Assignment to method "%s" used';
my $EXPL = <<'END_EXPL';
Use of methods as lvalues is uncommon and may indicate an accidental attempt
at assigning to a field or attribute, which is not commonly supported.
END_EXPL

sub violates {
  my ($self, $elem, undef) = @_;

  return if ! is_method_call($elem);

  my $sib = $elem;
  while ($sib = $sib->snext_sibling) {
    if ( $sib->isa( 'PPI::Token::Operator' ) ) {
      return
        if precedence_of( $sib->content ) != ASSIGNMENT_PRECEDENCE;
      return $self->violation( sprintf($DESC, $elem->content), $EXPL, $sib );
    }
  }
  return;
}

1;
__END__

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitLvalueMethods - Prohibit Methods
being used as lvalues

=head1 SYNOPSIS

In F<.perlcriticrc>:

  [Subroutines::ProhibitLvalueMethods]

=head1 DESCRIPTION

Use of methods as lvalues is uncommon. For less experienced Perl authors, or
author primarily experienced in other languages, lvalue methods can be
confusing or can get used accidentally.

This policy blocks lvalue calls to methods. It does not block declaring a
method as lvalue.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2022 the Perl::Critic::Policy::Subroutines::ProhibitLvalueMethods
L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
