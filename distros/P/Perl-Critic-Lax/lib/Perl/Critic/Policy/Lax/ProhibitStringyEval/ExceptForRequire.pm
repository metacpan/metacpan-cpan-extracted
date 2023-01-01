use strict;
use warnings;
package Perl::Critic::Policy::Lax::ProhibitStringyEval::ExceptForRequire 0.014;
# ABSTRACT: stringy eval is bad, but it's okay just to "require"

#pod =head1 DESCRIPTION
#pod
#pod Sure, everybody sane agrees that stringy C<eval> is usually a bad thing, but
#pod sometimes you need it, and you don't want to have to stick a C<no critic> on
#pod the end, because dangit, what you are doing is I<just not wrong>!
#pod
#pod See, C<require> is busted.  You can't pass it a variable containing the name of
#pod a module and have it look through C<@INC>.  That has lead to this common idiom:
#pod
#pod   eval qq{ require $module } or die $@;
#pod
#pod This policy acts just like BuiltinFunctions::ProhibitStringyEval, but makes an
#pod exception when the content of the string is PPI-parseable Perl that looks
#pod something like this:
#pod
#pod   require $module
#pod   require $module[2];
#pod   use $module (); 1;
#pod
#pod Then again, maybe you should use L<Module::Runtime>.
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy);

my $DESCRIPTION = 'Expression form of "eval" for something other than require';
my $EXPLANATION = <<'END_EXPLANATION';
It's okay to use stringy eval to require a module by name, but otherwise it's
probably a mistake.
END_EXPLANATION

sub default_severity { return $SEVERITY_HIGHEST  }
sub default_themes   { return qw( danger )       }
sub applies_to       { return 'PPI::Token::Word' }

sub _arg_is_ok {
  my ($self, $arg) = @_;

  return unless $arg->isa('PPI::Token::Quote::Double')
             or $arg->isa('PPI::Token::Quote::Interpolate');

  my $string = $arg->string;

  return unless my $doc = eval { PPI::Document->new(\$string) };

  my @children = $doc->schildren;

  # We only allow {require} and {require;number}
  return if @children > 2;
  return unless defined $children[0]
             && $children[0]->isa('PPI::Statement::Include');

  # We could give up if the Include's second child isn't a Symbol, but... eh!

  # So, we know it's got a require first.  If that's all, great.
  return 1 if @children == 1;

  # Otherwise, it must end in something like {1} or {1;}
  return unless $children[1]->isa('PPI::Statement');

  my @tail_bits = $children[1]->schildren;

  return if @tail_bits > 2
         or ! $tail_bits[0]->isa('PPI::Token::Number')
         or ($tail_bits[1] && $tail_bits[1] ne ';');

  return 1;
}

sub violates {
  my ($self, $elem) = @_;

  return if $elem ne 'eval';
  return unless is_function_call($elem);

  my $sib = $elem->snext_sibling();
  return unless $sib;
  my $arg = $sib->isa('PPI::Structure::List') ? $sib->schild(0) : $sib;

  # Blocks are always just fine!
  return if not($arg) or $arg->isa('PPI::Structure::Block');

  # It's OK if the string we're evaluating is just "require $var"
  return if $self->_arg_is_ok($arg);

  # Otherwise, you are in trouble.
  return $self->violation($DESCRIPTION, $EXPLANATION, $elem);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Lax::ProhibitStringyEval::ExceptForRequire - stringy eval is bad, but it's okay just to "require"

=head1 VERSION

version 0.014

=head1 DESCRIPTION

Sure, everybody sane agrees that stringy C<eval> is usually a bad thing, but
sometimes you need it, and you don't want to have to stick a C<no critic> on
the end, because dangit, what you are doing is I<just not wrong>!

See, C<require> is busted.  You can't pass it a variable containing the name of
a module and have it look through C<@INC>.  That has lead to this common idiom:

  eval qq{ require $module } or die $@;

This policy acts just like BuiltinFunctions::ProhibitStringyEval, but makes an
exception when the content of the string is PPI-parseable Perl that looks
something like this:

  require $module
  require $module[2];
  use $module (); 1;

Then again, maybe you should use L<Module::Runtime>.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes <cpan@semiotic.systems>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
