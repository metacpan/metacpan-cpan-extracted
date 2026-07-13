package Perl::Critic::PJCJ::Fixer v0.3.0;

use v5.26.0;
use strict;
use warnings;
use feature      qw( signatures );
use experimental qw( signatures );

use List::Util qw( all any );
use PPI        ();
use Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting ();

my $Max_passes    = 10;
my %Interpolating = map { $_ => 1 } qw(
  PPI::Token::Quote::Double
  PPI::Token::Quote::Interpolate
  PPI::Token::QuoteLike::Command
);

sub _interpolates ($self, $elem) {
  # perlop: qx does not interpolate when its delimiter is ''
  return 0
    if ref $elem eq "PPI::Token::QuoteLike::Command"
    && $elem->content =~ /\Aqx\s*'/;
  $Interpolating{ ref $elem } // 0
}

sub new ($class) {
  my $policy
    = Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting->new;
  bless { policy => $policy }, $class
}

# Only valid for content free of quote-sensitive escapes; conversion call
# sites guard with the policy's has_quote_sensitive_escapes predicate
sub _decode_double ($self, $raw) { $raw =~ s/\\(.)/$1/gsr }

sub _decode_q ($self, $raw, $start, $end) {
  $raw =~ s/\\([\\\Q$start$end\E])/$1/gr
}

sub _decode_delimiters ($self, $raw, $start, $end) {
  $raw =~ s/\\(.)/$1 eq $start || $1 eq $end ? $1 : "\\$1"/gser
}

sub _encode_single ($self, $value) {
  "'" . $self->{policy}->escape_single_quoted($value) . "'"
}

sub _encode_double ($self, $value) {
  '"' . ($value =~ s/\\/\\\\/gr) . '"'
}

sub _normalised_value ($self, $elem) {
  my $class = ref $elem;
  return $elem->literal if $class eq "PPI::Token::Quote::Single";
  return $self->_decode_double($elem->string)
    if $class eq "PPI::Token::Quote::Double";
  return join "\0", $elem->literal if $class eq "PPI::Token::QuoteLike::Words";

  my ($start, $end, $raw) = $self->{policy}->parse_quote_token($elem);
  return $self->_decode_q($raw, $start, $end)
    if $class eq "PPI::Token::Quote::Literal";

  # Interpolate; a Command never reaches here because _value_preserved
  # compares interpolating token pairs via _canonical
  $self->_decode_double($raw)
}

sub _balanced ($self, $content, $start, $end) {
  my $depth = 0;
  for my $char (split //, $content) {
    $depth++ if $char eq $start;
    if ($char eq $end) {
      $depth--;
      return 0 if $depth < 0;
    }
  }
  $depth == 0
}

sub _delimit_content ($self, $content, $start, $end) {
  return $content if $content !~ /[\Q$start$end\E]/;
  return          if $content =~ /\\/;
  return $content if $self->_balanced($content, $start, $end);
  $content =~ s/([\Q$start$end\E])/\\$1/gr
}

sub _operator_replacement ($self, $elem, $op, $start, $end) {
  my $class = ref $elem;
  my $content;

  if ($class eq "PPI::Token::Quote::Single") {
    $content = $elem->literal =~ s/([\\\Q$start$end\E])/\\$1/gr;
    return "$op$start$content$end";
  }

  if ($class eq "PPI::Token::Quote::Double") {
    # An interpolating target keeps the escapes bar the quote; a literal
    # target (q, qw) takes the fully decoded value
    $content
      = $op eq "qq" || $op eq "qx"
      ? $elem->string =~ s/\\"/"/gr
      : $self->_decode_double($elem->string);
  } else {
    my ($old_start, $old_end, $raw) = $self->{policy}->parse_quote_token($elem);
    $content = $raw =~ s/\\([\Q$old_start$old_end\E])/$1/gr;
  }

  $content = $self->_delimit_content($content, $start, $end);
  defined $content ? "$op$start$content$end" : undef
}

sub _replacement ($self, $elem, $fix) {
  my $class = ref $elem;
  my $type  = $fix->{type};

  return $self->_operator_replacement($elem, $fix->{op}, $fix->{start},
    $fix->{end})
    if $type eq "operator";

  if ($class eq "PPI::Token::Quote::Single") {
    return $self->_encode_double($elem->literal) if $type eq "double";
  } elsif ($class eq "PPI::Token::Quote::Double") {
    return $self->_encode_single($self->_decode_double($elem->string))
      if $type eq "single"
      && !$self->{policy}->has_quote_sensitive_escapes($elem->string);
  } elsif ($class eq "PPI::Token::Quote::Literal") {
    my ($start, $end, $raw) = $self->{policy}->parse_quote_token($elem);
    my $value = $self->_decode_q($raw, $start, $end);
    return $self->_encode_double($value) if $type eq "double";
    return $self->_encode_single($value) if $type eq "single";
  } elsif ($class eq "PPI::Token::Quote::Interpolate") {
    my ($start, $end, $raw) = $self->{policy}->parse_quote_token($elem);
    return '"' . $self->_decode_delimiters($raw, $start, $end) . '"'
      if $type eq "double";
    return $self->_encode_single($self->_decode_double($raw))
      if $type eq "single"
      && !$self->{policy}->has_quote_sensitive_escapes($raw);
  }

  undef
}

sub _canonical ($self, $elem) {
  my ($start, $end, $raw) = $self->{policy}->parse_quote_token($elem);
  $self->_decode_delimiters($raw, $start, $end)
}

sub _value_preserved ($self, $elem, $new_source) {
  my $code = "$new_source;";

  # uncoverable branch true note:code is never empty so PPI always parses
  my $doc = PPI::Document->new(\$code) or return 0;
  my ($token) = grep {
    $_->isa("PPI::Token::Quote") || $_->isa("PPI::Token::QuoteLike")
  } $doc->tokens;

  # uncoverable branch true
  # uncoverable condition left note:every replacement contains a quote token
  # uncoverable condition right note:PPI serialisation is faithful
  return 0 unless $token && $doc->serialize eq $code;
  if (
       $elem->isa("PPI::Token::QuoteLike::Command")
    || $token->isa("PPI::Token::QuoteLike::Command")
  ) {
    return 0 if $self->_interpolates($elem) != $self->_interpolates($token);
    return $self->_canonical($token) eq $self->_canonical($elem);
  }
  return $self->_canonical($token) eq $self->_canonical($elem)
    if $Interpolating{ ref $token } && $Interpolating{ ref $elem };
  $self->_normalised_value($token) eq $self->_normalised_value($elem)
}

sub _apply_replacement ($self, $elem, $fix) {
  my $new = $self->_replacement($elem, $fix);
  return 0 unless defined $new && $self->_value_preserved($elem, $new);
  $elem->set_content($new);
  1
}

sub _remove_include_parens ($self, $elem) {
  my $list = $self->{policy}->statement_level_list($elem);
  return 0 unless $list;

  my @kids = $list->children;
  while (@kids && !$kids[0]->significant)  { (shift @kids)->delete }
  while (@kids && !$kids[-1]->significant) { (pop @kids)->delete }
  unless (@kids) {
    my $prev = $list->previous_sibling;
    $prev->delete unless $prev->significant;
  }
  $list->start->set_content("");
  $list->finish->set_content("");
  1
}

sub _include_argument_span ($self, $elem) {
  # No module means no import arguments; ->arguments dies on a bare "use"
  return unless $elem->module;
  my @args = $elem->arguments or return;
  my (@span, $in);
  for my $child ($elem->children) {
    $in ||= $child == $args[0];
    push @span, $child if $in;
    last if $child == $args[-1];
  }
  @span
}

sub _span_has_comment ($self, @span) {
  any {
    $_->isa("PPI::Token::Comment")
      || ($_->isa("PPI::Node") && $_->find_any("PPI::Token::Comment"))
  } @span
}

sub _fix_include ($self, $elem, $fix) {
  return $self->_remove_include_parens($elem)
    if $fix->{type} eq "remove_parens";
  return 0 unless $fix->{type} eq "operator" && $fix->{op} eq "qw";

  my @span = $self->_include_argument_span($elem);
  return 0 unless @span;

  my @words;
  if (
      !$self->_span_has_comment(@span)
    && $self->{policy}->collect_qw_words(\@words, @span)
    && all { $self->{policy}->qw_word_ok($_) } @words
  ) {
    $span[0]->insert_before(PPI::Token->new("qw( @words )"));
    $_->delete for @span;
    return 1;
  }

  my $qw_tokens = $elem->find("PPI::Token::QuoteLike::Words") or return 0;
  my $applied   = 0;
  for my $token (@$qw_tokens) {
    next         if $token->content =~ /\Aqw\s*\Q$fix->{start}\E/;
    $applied = 1 if $self->_apply_replacement($token, $fix);
  }
  $applied
}

sub _apply_fix ($self, $elem, $fix) {
  $elem->isa("PPI::Statement::Include")
    ? $self->_fix_include($elem, $fix)
    : $self->_apply_replacement($elem, $fix)
}

sub _in_range ($self, $elem, $lines) {
  return 1 unless $lines;
  my $line = $elem->line_number;
  $line >= $lines->[0] && $line <= $lines->[1]
}

sub _shift_range ($self, $lines, $delta) {
  $lines->[1] += $delta if $lines;
}

sub _fix_once ($self, $source, $lines) {
  my $doc = PPI::Document->new(\$source) or return $source;

  my @fixes;
  $doc->find(
    sub ($top, $elem) {
      return 0 unless $self->_in_range($elem, $lines);
      my ($violation) = $self->{policy}->violates($elem, $doc);
      return 0 unless $violation;
      my $fix
        = $violation->can("fix")
        ? $violation->fix
        : $self->{policy}->fix_data($violation->description);
      if ($fix) {
        push @fixes, [$elem, $fix];
      } else {
        my $msg = $violation->description;
        warn "Perl::Critic::PJCJ::Fixer: no fix mapping for '$msg' at line "
          . $elem->line_number . "\n"
          unless $self->{warned}{$msg}++;
      }
      0
    }
  );
  return $source unless @fixes;
  my $applied = 0;
  for my $entry (@fixes) {
    my ($elem, $fix) = @$entry;
    my $before = $elem->content =~ tr/\n//;
    $applied = 1 if $self->_apply_fix($elem, $fix);
    $self->_shift_range($lines, ($elem->content =~ tr/\n//) - $before);
  }
  return $source unless $applied;

  $doc->serialize
}

sub _restore_crlf ($self, $source, $fixed) {
  return $fixed unless $source =~ /\r\n/;
  return $fixed if $source     =~ /\r(?!\n)|(?<!\r)\n/;
  $fixed                       =~ s/\n/\r\n/gr
}

sub _finish ($self, $source, $current) {
  return $current if $current eq $source;
  $self->_restore_crlf($source, $current)
}

sub fix ($self, $source, %opts) {
  my $lines   = $opts{lines} ? [$opts{lines}->@*] : undef;
  my $current = $source;
  $self->{warned} = {};
  my %seen;
  for (1 .. $Max_passes) {
    $seen{$current} = 1;
    my $next = $self->_fix_once($current, $lines);
    return $self->_finish($source, $next) if $next eq $current;
    if ($seen{$next}) {
      warn "Perl::Critic::PJCJ::Fixer: fixes oscillate without "
        . "converging; the result may still violate the policy\n";
      return $self->_finish($source, $next);
    }
    $current = $next;
  }
  warn "Perl::Critic::PJCJ::Fixer: fixes still changing after "
    . "$Max_passes passes; giving up\n";
  $self->_finish($source, $current)
}

"
A painter on the shore
Imagined all the world
Within the snowflake on his palm
"

__END__

=pod

=head1 NAME

Perl::Critic::PJCJ::Fixer - automatically fix RequireConsistentQuoting
violations

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

  use Perl::Critic::PJCJ::Fixer;

  my $fixer = Perl::Critic::PJCJ::Fixer->new;
  my $fixed = $fixer->fix($source);

=head1 DESCRIPTION

This module rewrites Perl source so that it satisfies
L<Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting>. It
never decides for itself what to change: it runs the policy over the parsed
document and rewrites only the tokens the policy flags, computing each
replacement so that the runtime value of every string is preserved.

Source that the policy accepts, including all surrounding whitespace and
comments, is passed through byte for byte.

=head1 METHODS

=head2 new

Create a new fixer.

=head2 fix ($source, %opts)

Take Perl source as a string and return the fixed source. Source that cannot be
parsed is returned unchanged. Fixing repeats until no further changes are
needed, since one fix can enable the next suggestion.

Source receiving no applied fix is returned byte for byte, and a file using
CRLF line endings throughout keeps them. A file with mixed line endings is
normalised to LF when a fix applies.

Each violation from the policy carries its own structured fix, which the fixer
uses directly; for other violation sources it falls back to the policy's
C<fix_data> lookup keyed on the description. A violation with no fix by either
route is reported once on standard error and left unchanged.

A repeating or non-converging sequence of fixes is reported on standard
error and the current state returned.

The C<lines> option restricts fixes to elements starting within an inclusive
line range, while still parsing the whole document:

  my $fixed = $fixer->fix($source, lines => [ 10, 20 ]);

=head1 AUTHOR

Paul Johnson <paul@pjcj.net>

=head1 LICENCE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
