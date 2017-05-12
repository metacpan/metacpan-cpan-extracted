use strict;
use warnings;
package Perl::Critic::Policy::Tics::ProhibitLongLines;
# ABSTRACT: 80 x 40 for life!
$Perl::Critic::Policy::Tics::ProhibitLongLines::VERSION = '0.009';
#pod =head1 DESCRIPTION
#pod
#pod Please keep your code to about eighty columns wide, the One True Terminal
#pod Width.  Going over that occasionally is okay, but only once in a while.
#pod
#pod This policy always throws a violation for extremely long lines.  It will also
#pod throw a violation if there are too many lines that are slightly longer than the
#pod preferred maximum length.  If a only few lines exceed the preferred maximum
#pod width, they're let slide and only extremely long lines are violations.
#pod
#pod =head1 CONFIGURATION
#pod
#pod There are three configuration options for this policy:
#pod
#pod   base_max - the preferred maximum line length (default: 80)
#pod   hard_max - the length beyond which a line is "extremely long"
#pod              (default: base_max * 1.5)
#pod
#pod   pct_allowed - the percentage of total lines which may fall between base_max
#pod                 and hard_max before those violations are reported (default: 1)
#pod
#pod =cut

use Perl::Critic::Utils;
use parent qw(Perl::Critic::Policy);

sub default_severity { $SEVERITY_LOW   }
sub default_themes   { qw(tics)        }
sub applies_to       { 'PPI::Document' }

sub supported_parameters { qw(base_max hard_max pct_allowed) }

my %_default = (
  base_max    => 80,
  pct_allowed => 1,
);

sub new {
  my ($class, %arg) = @_;
  my $self = $class->SUPER::new(%arg);

  my %merge = (%_default, %arg);

  Carp::croak "base_max for Tics::ProhibitLongLines must be an int, one or more"
    unless $merge{base_max} =~ /\A\d+\z/ and $merge{base_max} >= 1;

  $merge{hard_max} = $merge{base_max} * 1.5 unless exists $merge{hard_max};

  Carp::croak "base_max for Tics::ProhibitLongLines must be an int, one or more"
    unless do { no warnings; ($merge{hard_max} = int($merge{hard_max})) >= 1 };

  Carp::croak "pct_allowed for Tics::ProhibitLongLines must be a positive int"
    unless $merge{pct_allowed} =~ /\A\d+\z/ and $merge{pct_allowed} >= 0;

  $self->{$_} = $merge{$_} for $self->supported_parameters;

  bless $self => $class;
}


sub violates {
  my ($self, $elem, $doc) = @_;

  $elem->prune('PPI::Token::Data');
  $elem->prune('PPI::Token::End');

  my @lines = split /(?:\x0d\x0a|\x0a\x0d|\x0d|\x0a)/, $elem->serialize;

  my @soft_violations;
  my @hard_violations;

  my $base  = $self->{base_max};
  my $limit = $self->{hard_max};

  my $top = $elem->top();
  my $fn  = $top->can('filename') ? $top->filename() : undef;

  LINE: for my $ln (1 .. @lines) {
    my $length = length $lines[ $ln - 1 ];

    next LINE unless $length > $base;

    if ($length > $limit) {
      my $viol = Perl::Critic::Tics::Violation::VirtualPos->new(
        "Line is over hard length limit of $limit characters.",
        "Keep lines to about $limit columns wide.",
        $doc,
        $self->get_severity,
      );

      $viol->_set_location([ $ln, 1, 1, $ln, $fn ], $lines[ $ln - 1 ]);

      push @hard_violations, $viol;
    } else {
      my $viol = Perl::Critic::Tics::Violation::VirtualPos->new(
        "Line is over base length limit of $base characters.",
        "Keep lines to about $limit columns wide.",
        $doc,
        $self->get_severity,
      );

      $viol->_set_location([ $ln, 1, 1, $ln, $fn ], $lines[ $ln - 1 ]);

      push @soft_violations, $viol;
    }
  }

  my $allowed = sprintf '%u', @lines * ($self->{pct_allowed} / 100);

  my $viols = @soft_violations + @hard_violations;
  if ($viols > $allowed) {
    return(@hard_violations, @soft_violations);
  } else {
    return @hard_violations;
  }
}

{
  package # hide
    Perl::Critic::Tics::Violation::VirtualPos;
  BEGIN {require Perl::Critic::Violation; our @ISA = 'Perl::Critic::Violation';}
  sub _set_location {
    my ($self, $pos, $line) = @_;
    $self->{__PACKAGE__}{pos}  = $pos;
    $self->{__PACKAGE__}{line} = $line;
  }
  sub location { $_[0]->{__PACKAGE__}{pos} }
  sub source   { $_[0]->{__PACKAGE__}{line} }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::Tics::ProhibitLongLines - 80 x 40 for life!

=head1 VERSION

version 0.009

=head1 DESCRIPTION

Please keep your code to about eighty columns wide, the One True Terminal
Width.  Going over that occasionally is okay, but only once in a while.

This policy always throws a violation for extremely long lines.  It will also
throw a violation if there are too many lines that are slightly longer than the
preferred maximum length.  If a only few lines exceed the preferred maximum
width, they're let slide and only extremely long lines are violations.

=head1 CONFIGURATION

There are three configuration options for this policy:

  base_max - the preferred maximum line length (default: 80)
  hard_max - the length beyond which a line is "extremely long"
             (default: base_max * 1.5)

  pct_allowed - the percentage of total lines which may fall between base_max
                and hard_max before those violations are reported (default: 1)

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
