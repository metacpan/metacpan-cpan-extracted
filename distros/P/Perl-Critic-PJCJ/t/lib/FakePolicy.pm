package FakePolicy;

use v5.26.0;
use strict;
use warnings;
use feature      qw( signatures );
use experimental qw( signatures );

use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();

sub new ($class, %args) {
  $args{real}
    = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;
  bless {%args}, $class
}

sub violates ($self, $elem, $doc) {
  my $flags = $self->{flags};
  return ref $elem eq $flags ? $self : () unless ref $flags eq "HASH";
  my $description = $flags->{ ref $elem } or return ();
  $self->{description} = $description;
  $self
}

sub description ($self) { $self->{description} }

sub fix_data ($self, $description) {
  $self->{real}->fix_data($description)
}

sub parse_quote_token ($self, $elem) {
  $self->{real}->parse_quote_token($elem)
}

sub would_interpolate ($self, $string) {
  $self->{real}->would_interpolate($string)
}

sub escape_single_quoted ($self, $string) {
  $self->{real}->escape_single_quoted($string)
}

sub has_quote_sensitive_escapes ($self, $string) {
  $self->{real}->has_quote_sensitive_escapes($string)
}

sub statement_level_list ($self, $elem) {
  $self->{real}->statement_level_list($elem)
}

"
And if I only could
I'd make a deal with God
"

__END__

=head1 NAME

FakePolicy - test double emitting violations the real policy never produces

=head1 SYNOPSIS

  use FakePolicy ();

  my $fixer = Perl::Critic::PJCJ::Fixer->new;
  $fixer->{policy} = FakePolicy->new(
    flags       => "PPI::Token::Quote::Single",
    description => "use ''",
  );

=head1 DESCRIPTION

Perl::Critic::PJCJ::Fixer contains guards for class and description
combinations the real policy never emits. This double flags every element of
the configured class with the configured description, so tests can drive the
fixer down those defensive paths and assert that unsafe fixes are declined.

=head1 METHODS

=head2 new (%args)

Create a policy double. C<flags> is the PPI class to flag and C<description>
is the description each violation carries. Alternatively C<flags> may be a
hashref mapping PPI classes to descriptions, so different classes can carry
different descriptions.

=head2 violates ($elem, $doc)

Return the double itself as the violation for every element whose class
matches C<flags>. When C<flags> is a hashref, the element's class selects
the description.

=head2 description

The configured description.

=head2 fix_data ($description)

Delegated to the real policy.

=head2 parse_quote_token ($elem)

Delegated to the real policy.

=head2 would_interpolate ($string)

Delegated to the real policy.

=head2 escape_single_quoted ($string)

Delegated to the real policy.

=head2 has_quote_sensitive_escapes ($string)

Delegated to the real policy.

=head2 statement_level_list ($elem)

Delegated to the real policy.

=head1 AUTHOR

Paul Johnson <paul@pjcj.net>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
