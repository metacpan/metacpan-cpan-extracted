package Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting v0.3.0;

use v5.26.0;
use strict;
use warnings;
use feature "signatures";
use experimental "signatures";

use parent qw( Perl::Critic::Policy );

use Exporter            qw( import );
use List::Util          qw( all any );
use Perl::Critic::Utils qw( $SEVERITY_MEDIUM );
use Scalar::Util        qw( refaddr weaken );

use Perl::Critic::PJCJ::Violation ();

our @EXPORT_OK = qw(
  desc_double desc_optimal desc_remove_parens desc_single desc_use_qw
);

sub desc_double ()          { 'use ""' }
sub desc_single ()          { "use ''" }
sub desc_use_qw ()          { "use qw()" }
sub desc_remove_parens ()   { "remove parentheses" }
sub desc_optimal ($display) { "use $display" }

my $Expl = "Quoting should be consistent and minimal";

my $Fix_double        = { type => "double" };
my $Fix_single        = { type => "single" };
my $Fix_remove_parens = { type => "remove_parens" };
my $Fix_use_qw = { type => "operator", op => "qw", start => "(", end => ")" };

sub _operator_fix ($self, $op, $delim) { {
  type  => "operator",
  op    => $op,
  start => $delim->{start},
  end   => $delim->{end},
} }

sub _render_fix ($self, $fix) {
  my $type = $fix->{type};
  return desc_double        if $type eq "double";
  return desc_single        if $type eq "single";
  return desc_remove_parens if $type eq "remove_parens";
  desc_optimal("$fix->{op}$fix->{start}$fix->{end}")
}

sub _fix_violation ($self, $fix, $elem) {
  Perl::Critic::PJCJ::Violation->new(
    $self->_render_fix($fix),
    $Expl, $elem, $self->get_severity,
  )->set_fix($fix)
}

sub supported_parameters ($self) { }
sub default_severity     ($self) { $SEVERITY_MEDIUM }
sub default_themes       ($self) { qw( cosmetic pjcj ) }

sub applies_to ($self) {
  #<<<
  qw(
    PPI::Statement::Include
    PPI::Token::Quote::Double
    PPI::Token::Quote::Interpolate
    PPI::Token::Quote::Literal
    PPI::Token::Quote::Single
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Words
  )
  #>>>
}

sub would_interpolate ($self, $string) {
  # This is the authoritative way to check - let PPI decide
  state %cache;
  return $cache{$string} if exists $cache{$string};

  # Neutralise embedded double quotes so wrapping in "..." is valid PPI
  my $safe         = $string =~ s/"/ /gr;
  my $test_content = qq("$safe");
  my $test_doc     = PPI::Document->new(\$test_content);

  my $would_interpolate = 0;
  $test_doc->find(
    sub ($top, $test_elem) {
      $would_interpolate = $test_elem->interpolations
        if $test_elem->isa("PPI::Token::Quote::Double");
      0
    }
  );

  $cache{$string} = $would_interpolate
}

sub escape_single_quoted ($self, $string) {
  # The inner content of a '...' literal: backslash-escape \ and '
  $string =~ s/([\\'])/\\$1/gr
}

sub would_interpolate_from_single_quotes ($self, $string) {
  $self->would_interpolate($self->escape_single_quoted($string))
}

sub parse_quote_token ($self, $elem) {
  my $content = $elem->content;

  # Handle all possible delimiters, not just bracket pairs
  # q must be last so qw/qq/qx aren't consumed as q + letter
  if ($content =~ /\A(?:(qw|qq|qx|q)\s*)?(.)(.*)(.)\z/s) {
    my ($op, $start_delim, $str, $end_delim) = ($1, $2, $3, $4);
    ($start_delim, $end_delim, $str, $op)
  }
}

sub _get_supported_delimiters ($self, $operator) {
  state %tables;
  (
    $tables{$operator} //= [
      { start => "(", end => ")", display => "${operator}()" },
      { start => "[", end => "]", display => "${operator}[]" },
      { start => "<", end => ">", display => "${operator}<>" },
      { start => "{", end => "}", display => "${operator}{}" },
    ]
  )->@*
}

sub find_optimal_delimiter ($self, $content, $operator, $start, $end) {
  my @delimiters = $self->_get_supported_delimiters($operator);

  my %count = (
    "(" => $content =~ tr/()//,
    "[" => $content =~ tr/[]//,
    "<" => $content =~ tr/<>//,
    "{" => $content =~ tr/{}//,
  );

  # Fewest delimiter occurrences in the content wins; ties are broken by the
  # order of @delimiters, which encodes the preference () > [] > <> > {}
  my $optimal = $delimiters[0];
  for my $delim (@delimiters) {
    $optimal = $delim
      if $count{ $delim->{start} } < $count{ $optimal->{start} };
  }

  my $current_is_optimal
    = $optimal->{start} eq $start && $optimal->{end} eq $end ? 1 : 0;

  ($optimal, $current_is_optimal)
}

sub _known_fixes ($self) {
  my @fixes = ($Fix_double, $Fix_single, $Fix_remove_parens);
  for my $op (qw( q qq qw qx )) {
    push @fixes, map $self->_operator_fix($op, $_),
      $self->_get_supported_delimiters($op);
  }
  @fixes
}

sub fix_data ($self, $description) {
  state $map = { map { ($self->_render_fix($_) => $_) } $self->_known_fixes };
  $map->{$description}
}

sub check_delimiter_optimisation ($self, $elem) {
  my ($start, $end, $content, $operator) = $self->parse_quote_token($elem);
  return unless defined $start;

  $operator //= "q" if $start eq "'";
  my ($optimal_delim, $current_is_optimal)
    = $self->find_optimal_delimiter($content, $operator, $start, $end);
  return $self->_fix_violation(
    $self->_operator_fix($operator, $optimal_delim), $elem
  ) unless $current_is_optimal;

  return
}

sub _quote_token_complete ($self, $elem) {
  # Only the final token of a document can be unterminated: the
  # tokeniser runs an unterminated quote to end of file
  return 1 if $elem->next_token;

  # A terminated token reparses to itself; an unterminated one absorbs
  # the appended semicolon
  my $code = $elem->content . ";";

  # uncoverable branch true note:the probe code is never empty
  my $doc = PPI::Document->new(\$code) or return 0;
  my ($token) = grep {
    $_->isa("PPI::Token::Quote") || $_->isa("PPI::Token::QuoteLike")
  } $doc->tokens;

  # uncoverable branch false note:the probe starts with a quote token
  $token && $token->content eq $elem->content
}

sub has_quote_sensitive_escapes ($self, $string) {
  $string =~ /
    \\(?:
      [tnrfbae]           |  # Single char escapes: \t \n \r \f \b \a \e
      x[0-9a-fA-F]*       |  # Hex escapes: \x1b \xff
      x\{[^}]*\}          |  # Hex braces: \x{1b} \x{263A}
      [0-7]{1,3}          |  # Octal: \033 \377
      o\{[^}]*\}          |  # Octal braces: \o{033}
      c.                  |  # Control chars: \c[ \cA
      N\{[^}]*\}          |  # Named chars: \N{name} \N{U+263A}
      [luLUEQF]              # String modification: \l \u \L \U \E \Q \F
    )
  /x
}

sub _has_newlines ($self, $string) {
  # Check if string contains literal newlines (not \n escape sequences)
  index($string, "\n") != -1
}

sub _extract_list_arguments ($self, $list) {
  my @args;
  for my $child ($list->children) {
    if ($child->isa("PPI::Statement::Expression")) {
      for my $expr_child ($child->children) {
        next unless $expr_child->significant;
        # Skip commas but keep fat comma (=>) and other significant operators
        next
          if $expr_child->isa("PPI::Token::Operator")
          && $expr_child->content eq ",";
        push @args, $expr_child;
      }
    } elsif ($child->isa("PPI::Statement") || $child->isa("PPI::Structure")) {
      # Handle other statements and structures (like hash constructors)
      push @args, $child;
    } else {
      next unless $child->significant;
      push @args, $child;
    }
  }
  @args
}

sub _extract_use_arguments ($self, $elem) {
  # No module means no import arguments; ->arguments dies on a bare "use"
  return () unless $elem->module;
  my @args;
  for my $child ($elem->arguments) {
    # Skip commas but keep fat comma (=>) and other significant operators
    next if $child->isa("PPI::Token::Operator") && $child->content eq ",";

    # If it's a list structure (parentheses), extract its contents
    if ($child->isa("PPI::Structure::List")) {
      push @args, $self->_extract_list_arguments($child);
    } else {
      push @args, $child;
    }
  }
  @args
}

sub _is_pragma ($self, $elem) {
  !!$elem->pragma
}

sub _any_arg_interpolates ($self, @args) {
  for my $arg (@args) {
    next if $arg->isa("PPI::Token::QuoteLike::Words");
    next unless $arg->can("string");
    return 1 if $self->would_interpolate($arg->string);
  }
  0
}

sub _use_statement_verdict ($self, $stmt) {
  my @args = $self->_extract_use_arguments($stmt);

  # Single-arg pragmas follow normal quoting rules
  return 0 if @args == 1 && $self->_is_pragma($stmt);

  # If interpolation is needed, don't treat this as a use statement
  # so individual strings get checked normally
  return 0 if $self->_any_arg_interpolates(@args);
  1
}

sub _cached_use_statement_verdict ($self, $stmt) {
  my $doc = $stmt->document or return $self->_use_statement_verdict($stmt);

  my $cached = $self->{_use_cache_doc};
  if (!$cached || refaddr($cached) != refaddr($doc)) {
    $self->{_use_cache_doc} = $doc;
    weaken $self->{_use_cache_doc};
    $self->{_use_cache} = {};
  }
  $self->{_use_cache}{ refaddr $stmt } //= $self->_use_statement_verdict($stmt)
}

sub _is_in_use_statement ($self, $elem) {
  my $current = $elem;
  while ($current) {
    return $self->_cached_use_statement_verdict($current)
      if $current->isa("PPI::Statement::Include")
      && $current->type =~ /^(use|no)$/;
    $current = $current->parent;
  }
  0
}

sub violates ($self, $elem, $) {
  state $dispatch = {
    "PPI::Token::Quote::Single"      => "check_single_quoted",
    "PPI::Token::Quote::Double"      => "check_double_quoted",
    "PPI::Token::Quote::Literal"     => "check_q_literal",
    "PPI::Token::Quote::Interpolate" => "check_qq_interpolate",
    "PPI::Token::QuoteLike::Words"   => "check_quote_operators",
    "PPI::Token::QuoteLike::Command" => "check_quote_operators",
    "PPI::Statement::Include"        => "check_use_statement",
  };

  my $class  = ref $elem;
  my $method = $dispatch->{$class} or return;

  # An unterminated quote token at end of file parses with its final
  # content character taken as the closing delimiter, so any suggestion
  # (and any autofix built on it) would delete characters. Leave broken
  # source alone.
  my $last = $elem->last_token;
  return
    if ($last->isa("PPI::Token::Quote") || $last->isa("PPI::Token::QuoteLike"))
    && !$self->_quote_token_complete($last);

  # Two shared guards apply to token classes before dispatch: tokens inside
  # a use/no statement are handled by check_use_statement, and string tokens
  # with literal newlines are exempt (see the Newlines POD section)
  if ($elem->isa("PPI::Token")) {
    return if $self->_is_in_use_statement($elem);
    return
      if $elem->isa("PPI::Token::Quote") && $self->_has_newlines($elem->string);
  }

  $self->$method($elem)
}

sub prepare_to_scan_document ($self, $) {
  delete $self->{_use_cache_doc};
  delete $self->{_use_cache};
  1
}

sub check_single_quoted ($self, $elem) {
  my $string = $elem->string;

  my $has_single_quotes = index($string, "'") != -1;
  my $has_double_quotes = index($string, '"') != -1;

  return $self->check_delimiter_optimisation($elem)
    if $has_single_quotes && $has_double_quotes;

  return if
    # Keep single quotes if the string contains double quotes
    $has_double_quotes ||
    # Check if string contains escape sequences that would have different
    # meanings between single vs double quotes. If so, preserve single quotes.
    $self->has_quote_sensitive_escapes($string) ||
    # Keep single quotes if double would introduce interpolation
    $self->would_interpolate_from_single_quotes($string);

  $self->_fix_violation($Fix_double, $elem)
}

sub check_double_quoted ($self, $elem) {
  my $string  = $elem->string;
  my $content = $elem->content;

  # Strip delimiters and remove \\ pairs so escaped backslashes before the
  # closing delimiter aren't mistaken for escaped specials
  my $inner = substr $content, 1, -1;
  (my $cleaned = $inner) =~ s/\\\\//g;

  # Check for escaped dollar/at signs or double quotes, but only suggest single
  # quotes if no other interpolation exists AND no dangerous escape sequences
  if (
       $cleaned =~ /\\[\$\@\"]/
    && !$self->has_quote_sensitive_escapes($string)
    && !$self->would_interpolate($string)
  ) {
    # An apostrophe would need escaping in '', so prefer q(), which adds no
    # escaping for the literal value
    return $self->_fix_violation($Fix_single, $elem)
      if index($string, "'") == -1;
    my $value = $string =~ s/\\(.)/$1/gsr;
    my ($optimal) = $self->find_optimal_delimiter($value, "q", '"', '"');
    return $self->_fix_violation($self->_operator_fix("q", $optimal), $elem);
  }

  # If has escaped double quotes, suggest qq() - by this point, the ''
  # suggestion was ruled out (escape sequences or interpolation present),
  # so qq() eliminates the quote escaping while preserving both
  if ($cleaned =~ /\\"/) {
    my ($optimal) = $self->find_optimal_delimiter($string, "qq", '"', '"');
    return $self->_fix_violation($self->_operator_fix("qq", $optimal), $elem);
  }

  return
}

sub check_q_literal ($self, $elem) {
  my $string = $elem->string;

  my $has_single_quotes = index($string, "'") != -1;
  my $has_double_quotes = index($string, '"') != -1;

  # Has both quote types - q() handles this cleanly
  return $self->check_delimiter_optimisation($elem)
    if $has_single_quotes && $has_double_quotes;

  if ($has_single_quotes) {
    return $self->would_interpolate_from_single_quotes($string)
      ? $self->check_delimiter_optimisation($elem)
      : $self->_fix_violation($Fix_double, $elem);
  }

  # Only double quotes (no single quotes) - single quotes always work:
  # they don't interpolate and can hold " without escaping
  return $self->_fix_violation($Fix_single, $elem) if $has_double_quotes;

  return $self->_fix_violation($Fix_single, $elem)
    if $self->would_interpolate_from_single_quotes($string);

  $self->_fix_violation($Fix_double, $elem)
}

sub _what_would_double_quotes_suggest ($self, $string) {
  my $would_interpolate = $self->would_interpolate($string);

  # Rules 1,2: If has escaped variables but no interpolation → suggest
  # single quotes
  return "''" if !$would_interpolate && ($string =~ /\\[\$\@]/);

  # Rule 1: If has quotes that need handling → suggest qq()
  my $has_single_quotes = index($string, "'") != -1;
  my $has_double_quotes = index($string, '"') != -1;

  if ($has_double_quotes) {
    return "qq()" if $would_interpolate || $has_single_quotes;
    return "''";  # Only double quotes, no interpolation
  }

  # Rules 1,2: Otherwise double quotes are fine
  undef
}

sub check_qq_interpolate ($self, $elem) {
  my $string = $elem->string;

  # Only preserve qq() if escape sequences are actually needed
  return $self->check_delimiter_optimisation($elem)
    if $self->has_quote_sensitive_escapes($string);

  my $double_quote_suggestion
    = $self->_what_would_double_quotes_suggest($string);

  # Rules 1,2: If double quotes would suggest single quotes, use single quotes
  if ($double_quote_suggestion && $double_quote_suggestion eq "''") {
    return $self->_fix_violation($Fix_single, $elem);
  }

  # Rule 1: If double quotes would suggest qq(), qq() is appropriate
  return $self->check_delimiter_optimisation($elem)
    if $double_quote_suggestion && $double_quote_suggestion eq "qq()";

  # Rule 1: Otherwise prefer simple double quotes. Every string containing a
  # double quote was handled above, so nothing here needs qq(); an apostrophe
  # needs no escaping in double quotes
  $self->_fix_violation($Fix_double, $elem)
}

sub check_quote_operators ($self, $elem) {
  my ($current_start, $current_end, $content, $operator)
    = $self->parse_quote_token($elem);
  return unless defined $current_start;

  # perlop: qx interpolates "unless the delimiter is ''". The single-quote
  # delimiter is semantic, not stylistic, so it is exempt from the
  # delimiter rules
  return if $operator eq "qx" && $current_start eq "'";

  # Don't skip empty content - () is preferred even for empty quotes
  my ($optimal_delim, $current_is_optimal) = $self->find_optimal_delimiter(
    $content, $operator, $current_start, $current_end
  );

  return $self->_fix_violation(
    $self->_operator_fix($operator, $optimal_delim), $elem
  ) if !$current_is_optimal;

  return
}

sub statement_level_list ($self, $elem) {
  # No module means no arguments; ->arguments dies on a bare "use"
  return unless $elem->module;
  my ($first) = $elem->arguments;
  $first && $first->isa("PPI::Structure::List") ? $first : undef
}

sub _analyse_argument_types ($self, $elem, @args) {

  my $fat_comma
    = any { $_->isa("PPI::Token::Operator") && $_->content eq "=>" } @args;
  # Anything the qw rewrite doesn't understand makes the statement
  # complex. A real module version never gets here: ->arguments excludes
  # it, so any number is part of the import list itself.
  my $complex_expr = any {
    !(   $_->isa("PPI::Token::Quote")
      || $_->isa("PPI::Token::QuoteLike::Words")
      || ($_->isa("PPI::Token::Operator") && $_->content eq "=>")
      || ($_->isa("PPI::Token::Word")     && $_->content =~ /\A-\w+\z/))
  } @args;
  my $version = any {
         $_->isa("PPI::Token::Number::Version")
      || $_->isa("PPI::Token::Number::Float")
  } @args;
  my $simple_strings = any {
         $_->isa("PPI::Token::Quote::Single")
      || $_->isa("PPI::Token::Quote::Double")
  } @args;
  my $q_operators = any {
         $_->isa("PPI::Token::Quote::Literal")
      || $_->isa("PPI::Token::Quote::Interpolate")
  } @args;

  # Statement-level parentheses: a list wrapping the whole argument list
  my $parens = defined $self->statement_level_list($elem);

  ($fat_comma, $complex_expr, $version, $simple_strings, $q_operators, $parens)
}

sub collect_qw_words ($self, $words, @elements) {
  for my $el (@elements) {
    next unless $el->significant;
    my $class = ref $el;
    if ($class eq "PPI::Token::Quote::Single") {
      push @$words, $el->literal;
    } elsif ($class eq "PPI::Token::Quote::Literal") {
      my ($start, $end, $raw) = $self->parse_quote_token($el);
      push @$words, $raw =~ s/\\([\\\Q$start$end\E])/$1/gr;
    } elsif (
      $class eq "PPI::Token::Quote::Double"
      || $class eq "PPI::Token::Quote::Interpolate"
    ) {
      my $raw = $el->string;
      return 0 if $self->would_interpolate($raw);
      return 0 if $raw =~ /\\(?![\\"])/;
      push @$words, $raw =~ s/\\([\\"])/$1/gr;
    } elsif ($class eq "PPI::Token::QuoteLike::Words") {
      push @$words, $el->literal;
    } elsif ($class eq "PPI::Token::Word" && $el->content =~ /\A-\w+\z/) {
      push @$words, $el->content;
    } elsif ($class eq "PPI::Token::Operator" && $el->content eq ",") {
      next;
    } elsif (
      $el->isa("PPI::Structure::List")
      || $el->isa("PPI::Statement::Expression")
    ) {
      return 0 unless $self->collect_qw_words($words, $el->children);
    } else {
      return 0;
    }
  }
  @$words ? 1 : 0
}

sub qw_word_ok ($self, $word) {
  $word =~ /\A[^\s()\\]+\z/
}

sub _use_args_qw_representable ($self, @args) {
  my @words;
  return 0 unless $self->collect_qw_words(\@words, @args);
  all { $self->qw_word_ok($_) } @words
}

sub _use_qw_violation ($self, $elem, @args) {
  return () unless $self->_use_args_qw_representable(@args);
  $self->_fix_violation($Fix_use_qw, $elem)
}

sub _scan_qw ($self, $elem, $qw_ref, $qw_parens_ref) {
  if ($elem->isa("PPI::Token::QuoteLike::Words")) {
    $$qw_ref        = 1;
    $$qw_parens_ref = 0 if $elem->content !~ /\Aqw\s*\(/;
  }

  # Recursively check children (for structures like lists)
  if ($elem->can("children")) {
    $self->_scan_qw($_, $qw_ref, $qw_parens_ref) for $elem->children;
  }
}

sub _summarise_use_arguments ($self, @args) {
  my $has_qw         = 0;
  my $qw_uses_parens = 1;

  $self->_scan_qw($_, \$has_qw, \$qw_uses_parens) for @args;

  ($has_qw, $qw_uses_parens)
}

sub check_use_statement ($self, $elem) {
  # Check "use" and "no" statements, but not "require"
  return unless $elem->type =~ /^(use|no)$/;

  my @args = $self->_extract_use_arguments($elem) or return;

  my ($has_qw, $qw_uses_parens) = $self->_summarise_use_arguments(@args);

  # Check for different types of arguments
  my (
    $has_fat_comma,      $has_complex_expr, $has_version,
    $has_simple_strings, $has_q_operators,  $has_parens,
  ) = $self->_analyse_argument_types($elem, @args);

  # Rule 4: Special cases - no violation
  return () if $has_version && @args == 1;  # Single version number

  # Pragmas with a single argument allow quotes
  return () if @args == 1 && $self->_is_pragma($elem);

  # Rule 1: qw() without parens should use qw()
  return $self->_fix_violation($Fix_use_qw, $elem)
    if $has_qw && !$qw_uses_parens;

  # Rules 2, 3: fat comma or complex expressions should have no parentheses
  if ($has_fat_comma || $has_complex_expr) {
    return $self->_fix_violation($Fix_remove_parens, $elem) if $has_parens;
    return ();
  }

  # If interpolation is needed, don't suggest qw() - let normal rules apply
  return () if $self->_any_arg_interpolates(@args);

  # Rule 1: string arguments, with or without qw(), should be qw() alone
  return $self->_use_qw_violation($elem, @args)
    if $has_simple_strings || $has_q_operators;

  ()
}

"
I see the people working
And see it working for them
And so I want to join in
But then I find it hurt me
"

__END__

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting - Use
consistent and optimal quoting

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

  # Bad examples:
  my $greeting = 'hello';                 # use double quotes for simple strings
  my @words    = qw{word(with)parens};    # use qw[] for unbalanced content
  my $text     = qq(simple);              # use "" instead of qq()
  my $file     = q!path/to/file!;         # use "" instead of q()
  use Config 'arg1', 'arg2';              # simple strings should use qw()
  use Quux ( $VERSION );                  # complex expressions need no
                                          # parentheses

  # Good examples:
  my $greeting = "hello";                 # double quotes for simple strings
  my @words    = qw[ word(with)parens ];  # optimal delimiter choice
  my $text     = "simple";                # "" preferred over qq()
  my $file     = "path/to/file";          # "" reduces punctuation
  use Config qw( arg1 arg2 );             # simple use arguments use qw()
  use Quux $VERSION;                      # no parentheses for complex
                                          # expressions

=head1 DESCRIPTION

This policy enforces consistent quoting to improve code readability and
maintainability. It applies three simple rules:

=head2 Rule 1: Reduce punctuation

Prefer fewer characters and simpler syntax. Prefer real quotes over quote-like
operators when possible.

  # Good
  my $text    = "hello world";            # "" preferred over qq()
  my $literal = 'contains$literal';       # '' preferred over q()
  my $path    = "path/to/file";           # simple quotes reduce punctuation

  # Bad
  my $text    = qq(hello world);          # unnecessary quote operator
  my $literal = q(contains$literal);      # unnecessary quote operator
  my $path    = q!path/to/file!;          # unnecessary quote operator

=head2 Rule 2: Prefer interpolated strings

If it doesn't matter whether a string is interpolated or not, prefer the
interpolated version (double quotes).

  # Good
  my $name  = "John";                     # simple string uses double quotes
  my $email = 'user@domain.com';          # literal @ uses single quotes
  my $var   = 'Price: $10';               # literal $ uses single quotes

  # Bad
  my $name = 'John';                      # should use double quotes

=head2 Rule 3: Use bracket delimiters in preference order

If the best choice is a quote-like operator, prefer C<()>, C<[]>, C<< <> >>,
or C<{}> in that order.

  # Good
  my @words = qw( simple list );          # () preferred when content is simple
  my @data  = qw[ has(parens) ];          # [] optimal - handles unbalanced ()
  my $cmd   = qx( has[brackets] );        # () optimal - handles unbalanced []
  my $text  = q( has<angles> );           # () optimal - handles unbalanced <>

  # Bad - exotic delimiters
  my @words = qw/word word/;              # should use qw()
  my $path  = q|some|path|;               # should use ""
  my $text  = qq#some#text#;              # should use ""

The one exception is C<qx> with a single-quote delimiter. perlop defines
C<qx''> as non-interpolating, so that delimiter is semantic rather than
stylistic and is always left alone.

  # Good - qx'' deliberately suppresses interpolation
  my $pid = qx'echo $$';                  # the shell sees $$, not Perl

=head2 Special Case: Use and No statements

Use and no statements have special quoting requirements for their import lists.
Both C<use> and C<no> statements follow identical rules:

=over 4

=item * Modules with no arguments or empty parentheses are acceptable

=item * Single version numbers (e.g., C<1.23>, C<v5.10.0>) are exempt from all
rules

=item * Fat comma (C<=E<gt>>) arguments should have no parentheses for
readability

=item * Complex expressions (variables, conditionals, structures) should have
no parentheses

=item * Arguments requiring interpolation follow normal string quoting rules
individually

=item * Simple string arguments without interpolation should use C<qw()>
with parentheses only

=item * Pragmas (lowercase module names, as PPI defines them) with a single
argument also allow quoted strings, with normal quoting rules applied

=back

This design promotes readability whilst maintaining compatibility with
L<perlimports|https://metacpan.org/pod/perlimports>.

  # Good - basic cases
  use Foo;                                # no arguments
  use Bar ();                             # empty parentheses
  use Baz 1.23;                           # version numbers exempt
  no warnings;                            # no statements follow same rules

  # Good - fat comma arguments (no parentheses)
  use Data::Printer
    deparse       => 0,
    show_unicode  => 1,
    class         => { expand => "all" };

  # Good - complex expressions (no parentheses)
  use Module $VERSION;
  use Config $DEBUG ? "verbose" : "quiet";
  use Handler { config => "file.conf" };

  # Good - interpolation cases (normal string rules)
  use lib "$HOME/perl", "/usr/lib";       # interpolation prevents qw()
  no warnings "$category", "another";     # applies to no statements too

  # Good - simple strings use qw()
  use Foo qw( arg1 arg2 arg3 );           # multiple simple arguments
  no warnings qw( experimental uninitialized );

  # Good - pragmas with a single argument allow quotes
  use feature "class";                    # pragma, single arg, double quotes
  use strict "refs";                      # pragma, single arg, double quotes
  no warnings "experimental";             # no pragma, single arg, double quotes
  use feature qw( class );                # qw() is still fine too

  # Bad - incorrect quoting
  use Foo 'single_arg';                   # single quotes should use qw()
  use Bar "arg1", "arg2";                 # simple strings need qw()
  use Baz qw[ arg1 arg2 ];                # qw() must use parentheses only
  use Qux ( key => "value" );             # fat comma needs no parentheses
  use Quux ( $VERSION );                  # complex expressions need no
                                          # parentheses
  use feature 'class';                    # pragma single arg prefers ""

=head2 Special Case: Newlines

Strings containing newlines do not follow the rules.  But note that outside of a
few very special cases, strings with literal newlines are not a good idea.

This exemption applies to string tokens only (C<''>, C<"">, C<q()>, C<qq()>).
C<qw()> and C<qx()> keep their delimiter checks, because there a newline is
merely a word separator or command formatting and does not affect the delimiter
choice.

  # Allowed
  my $text = qq(
    line 1
    line 2
  );

=head2 Scope

This policy covers string literals (C<"">, C<''>), quote operators (C<q()>,
C<qq()>), word lists (C<qw()>), command execution (C<qx()>), and use/no
statement import lists.

The following quote-like constructs are B<not> checked, as they have
fundamentally different quoting semantics:

=over 4

=item * Regular expressions: C<m//>, C<qr//>

=item * Substitutions: C<s///>

=item * Transliterations: C<tr///>, C<y///>

=item * Heredocs: C<< <<EOF >>

=back

=head2 RATIONALE

=over 4

=item * Minimising escape characters improves readability and reduces errors

=item * Simple quotes are preferred over their C<q()> and C<qq()> equivalents
when possible

=item * Double quotes are preferred for consistency and to allow potential
interpolation

=item * Many years ago, Tom Christiansen wrote a lengthy article on how perl's
default quoting system is interpolation, and not interpolating means something
extraordinary is happening. I can't find the original article, but you can see
that double quotes are used by default in The Perl Cookbook, for example.

=item * Only bracket delimiters should be used (no exotic delimiters like C</>,
  C<|>, C<#>, etc.)

=item * Optimal delimiter selection reduces visual noise in code

=back

=head1 AFFILIATION

This Policy is part of the Perl::Critic::PJCJ distribution.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 EXAMPLES

=head2 String Literals

  # Bad
  my $greeting = 'hello';                 # Rule 2: should use double quotes
  my $email    = "user\@domain.com";      # Rule 2: should use single quotes
                                          # (escaped @)
  my $path     = 'C:\Program Files';      # Rule 2: should use double quotes

  # Good
  my $greeting = "hello";                 # double quotes for simple strings
  my $email    = 'user@domain.com';       # single quotes for literal @
  my $path     = "C:\\Program Files";     # double quotes handle backslashes

=head2 Quote Operators

  # Bad
  my $simple = q(hello);                  # Rule 1: should use ''
  my $text   = qq(hello);                 # Rule 1: should use ""
  my @words  = qw/one two/;               # Rule 3: should use qw( )
  my $cmd    = qx|ls|;                    # Rule 3: should use qx( )

  # Good
  my $simple = 'hello$literal';           # single quotes for literal content
  my $text   = "hello";                   # double quotes preferred
  my @words  = qw( one two );             # bracket delimiters only
  my $cmd    = qx( ls );                  # bracket delimiters only

=head2 Optimal Delimiter Selection

  # Bad - unbalanced delimiters
  my @list = qw(word(with)parens);        # Rules 1, 3: unbalanced () in content
  my $cmd  = qx[command[with]brackets];   # Rules 1, 3: unbalanced [] in content
  my $text = q{word{with}braces};         # Rules 1, 3: unbalanced {} in content

  # Good - balanced delimiters
  my @list = qw[ word(with)parens ];      # [] handles parentheses in content
  my $cmd  = qx( command[with]brackets ); # () handles brackets in content

=head2 Complex Content

  # When content has multiple quote types, quote-like operators may be needed
  my $both = qq(has 'single' and "double" quotes); # qq() handles both
                                                    # quote types cleanly

=head2 Use and No Statement Examples

  # Bad
  use Foo 'single_arg';                   # single quotes should use qw()
  use Bar "arg1", "arg2";                 # simple strings need qw()
  use Baz qw[ arg1 arg2 ];                # qw() must use parentheses only
  use Qux ( key => "value" );             # fat comma should have no parentheses
  use Quux ( $VERSION );                  # complex expressions need no
                                          # parentheses
  use feature 'class';                    # pragma single arg prefers ""

  # Good
  use Foo;                                # no arguments
  use Bar ();                             # empty parentheses
  use Baz 1.23;                           # version numbers exempt
  use Qux qw( single_arg );               # simple string uses qw()
  use Quux qw( arg1 arg2 arg3 );          # multiple simple arguments
  no warnings qw( experimental uninitialized ); # no statements follow same
                                                  # rules

  # Pragma single-argument examples
  use feature "class";                    # pragma, single arg, double quotes
  use strict "refs";                      # pragma, single arg, double quotes
  no warnings "experimental";             # no pragma, single arg, double quotes
  no warnings ( "experimental" );         # parentheses are also exempt here
  use feature qw( class );                # qw() is still fine too

  # Fat comma examples (no parentheses)
  use Data::Printer
    deparse       => 0,
    show_unicode  => 1;
  use Config
    key           => "value",
    another_key   => { nested => "structure" };

  # Complex expression examples (no parentheses)
  use Module $VERSION;                    # variable argument
  use Config $DEBUG ? "verbose" : "quiet"; # conditional expression
  use Handler { config => "file.conf" };   # hash reference

  # Interpolation examples (normal string rules apply)
  use lib "$HOME/perl", "/usr/lib";       # interpolation prevents qw()
  use lib "$x/d1", "$x/d2";               # both strings need interpolation
  use lib "$HOME/perl", "static";         # mixed interpolation uses double
                                          # quotes
  no warnings "$category", "another";     # no statements handle
                                          # interpolation too

=head1 METHODS

=head2 desc_double

=head2 desc_single

=head2 desc_use_qw

=head2 desc_remove_parens

=head2 desc_optimal ($display)

The suggestion wording exported for tests, so the strings live in one place
instead of being duplicated as literals. Each returns the description a
violation carries: C<< use "" >>, C<use ''>, C<use qw()>,
C<remove parentheses> and C<< use $display >> respectively. They are available
via C<@EXPORT_OK>.

=head2 _operator_fix ($op, $delim)

Builds an operator fix structure for operator C<$op> and the delimiter hashref
C<$delim> (with C<start> and C<end> keys).

=head2 _render_fix ($fix)

Renders a fix structure as its user-visible suggestion string, which becomes
the violation's description (e.g. C<< use "" >>, C<use q[]>). This is the
single place the wording of a suggestion is produced.

=head2 _fix_violation ($fix, $elem)

Builds a L<Perl::Critic::PJCJ::Violation> for C<$elem> whose description is
L<_render_fix|/"_render_fix ($fix)"> of C<$fix>, whose explanation is the
static rationale, and which carries C<$fix> directly via C<< ->fix >>.

=head2 supported_parameters

This policy has no configurable parameters.

=head2 would_interpolate

Determines whether a string would perform variable interpolation if placed in
double quotes. This is critical for deciding between single and double quotes -
strings that would interpolate variables should use single quotes to preserve
literal content, while non-interpolating strings should use double quotes for
consistency.

Uses PPI's authoritative parsing to detect interpolation rather than regex
patterns, ensuring accurate detection of complex cases like literal variables.

=head2 escape_single_quoted ($string)

Encodes a string as the inner content of a single-quoted literal by
backslash-escaping backslashes and apostrophes. This is the single source of
single-quote encoding knowledge, shared with L<Perl::Critic::PJCJ::Fixer>.

=head2 would_interpolate_from_single_quotes

Tests whether a string from single quotes would interpolate if converted to
double quotes. This specialised version handles the challenge that PPI provides
decoded string content rather than the original source text.

When checking single-quoted strings, PPI's C<string()> method returns the
decoded content. For example, the source C<'price: \\$5.00'> becomes
C<'price: \$5.00'> in the content (with one backslash). To test interpolation
properly, this method reconstructs what the original escaping would have been
by re-escaping backslashes and apostrophes according to single-quote rules.

This ensures accurate detection of whether converting a single-quoted string to
double quotes would introduce unintended variable interpolation.

=head2 parse_quote_token

Extracts delimiter and content information from quote-like operators such as
C<qw{}>, C<q{}>, C<qq{}>, and C<qx{}>. Handles both bracket pairs (where start
and end delimiters differ) and symmetric delimiters (where they're the same).

This parsing is essential for delimiter optimisation, as it separates the
operator, delimiters, and content for independent analysis.

=head2 find_optimal_delimiter

Determines the best delimiter choice for a quote-like operator by analysing the
content for balanced delimiters. Implements the core logic for Rules 1 and 3:
choose delimiters that handle unbalanced content gracefully and prefer bracket
delimiters.

Only considers bracket delimiters C<()>, C<[]>, C<< <> >>, C<{}> as valid
options, rejecting exotic delimiters like C</>, C<|>, C<#>. When multiple
delimiters work equally well, ties are broken by the preference order
C<()> > C<[]> > C<< <> >> > C<{}>.

=head2 _known_fixes

Returns the list of every fix structure the policy can produce: the three plain
fixes plus one operator fix per supported delimiter of C<q>, C<qq>, C<qw> and
C<qx>. L<fix_data> is generated from this list.

=head2 fix_data

Maps a violation's description string to structured fix data, so that tools
such as L<Perl::Critic::PJCJ::Fixer> can resolve a fix without a live violation
object. The map is generated from L<_known_fixes|/"_known_fixes"> via
L<_render_fix|/"_render_fix ($fix)">, so it cannot drift from the wording the
policy actually emits. Violations from this policy also carry their fix
directly, so this lookup is only a fallback.

Returns a hashref describing the fix, or C<undef> for an unknown description:

  { type => "double" }         # use ""
  { type => "single" }         # use ''
  { type => "remove_parens" }  # remove parentheses
  { type  => "operator",       # use qw(), use q[], use qq<> ...
    op    => "qw",
    start => "(",
    end   => ")",
  }

=head2 check_delimiter_optimisation

Validates that quote-like operators use optimal delimiters according to Rules 1
and 3. This method coordinates parsing the current token and finding the
optimal alternative, issuing violations when the current choice is suboptimal.

Acts as a bridge between the parsing and optimisation logic, providing a
clean interface for the quote-checking methods.

=head2 has_quote_sensitive_escapes ($string)

Tests whether a string contains escape sequences (such as C<\n>, C<\x1b> or
C<\F>) that mean different things in single and double quotes. Such strings
keep their current quote style. This is the single source of the double-quote
escape list, shared with L<Perl::Critic::PJCJ::Fixer>, which must not decode
double-quoted content containing these escapes.

=head2 _extract_list_arguments

Recursively processes parenthesised argument lists within use/no statements.
Handles complex nested structures including expressions, statements, and
hash constructors whilst filtering out structural tokens that don't affect
quoting decisions.

=head2 _extract_use_arguments

Extracts and processes arguments from use/no statements, handling both bare
arguments and those enclosed in parentheses. Skips whitespace, commas, and
semicolons whilst preserving significant operators like fat comma (C<=E<gt>>).

Handles nested list structures by recursively extracting their contents,
ensuring all argument types are properly identified for rule enforcement.

=head2 _any_arg_interpolates

Checks whether any string argument in a list would interpolate if placed in
double quotes. Used by both C<check_use_statement> and C<_is_in_use_statement>
to determine whether a use/no statement's arguments require interpolation,
which affects whether C<qw()> can be suggested and whether individual tokens
should be checked under normal quoting rules.

=head2 violates

The main entry point for policy violation checking. Uses a dispatch table to
route different quote token types to their appropriate checking methods. This
design allows for efficient handling of the six different PPI token types that
represent quoted strings and quote-like operators.

Two shared guards are applied here, before dispatch, rather than in each
checking method: tokens inside a C<use>/C<no> statement (handled instead by
C<check_use_statement>) and string tokens containing literal newlines are both
left alone.

=head2 prepare_to_scan_document

Clears the per-document C<use>/C<no> statement verdict cache before each
document is scanned, and returns true. Perl::Critic reuses one policy instance
for every file in a run, so this override stops a cached verdict from one
document being read against another.

=head2 check_single_quoted

Enforces Rules 1 and 2 for single-quoted strings: prefer double quotes for
simple strings unless the content contains literal C<$> or C<@> characters that
shouldn't be interpolated, or the string contains double quotes that would
require special handling.

Also detects when C<q()> operators would be better than single quotes for
complex content, promoting cleaner alternatives.

=head2 check_double_quoted

Validates double-quoted strings to ensure they genuinely need interpolation.
Suggests single quotes when the content contains only literal C<$> or C<@>
characters with no actual interpolation, as this indicates the developer
intended literal content. When that literal content also contains an
apostrophe, C<q()> is suggested instead of single quotes, so that no escaping
is added.

This reduces unnecessary complexity and makes the code's intent clearer.

=head2 check_q_literal

Enforces Rules 1 and 3 for C<q()> operators. First ensures optimal
delimiter choice, then evaluates whether simpler quote forms would be more
appropriate.

Allows C<q()> when the content has both single and double quotes (making it
the cleanest option), but suggests simpler alternatives for basic content that
could use C<''> or C<"">.

=head2 check_qq_interpolate

Enforces Rules 1 and 3 for C<qq()> operators. First ensures optimal
delimiter choice, then determines whether simple double quotes would suffice.

The policy prefers C<""> over C<qq()> when the content doesn't contain double
quotes, as this reduces visual noise and follows common Perl conventions.

=head2 check_quote_operators

Handles C<qw()> and C<qx()> operators, focusing purely on delimiter
optimisation according to Rules 1 and 3. These operators don't have simpler
alternatives, so the policy only ensures they use the most appropriate
delimiters to handle unbalanced content gracefully.

=head2 statement_level_list ($elem)

Returns the C<PPI::Structure::List> wrapping a use/no statement's whole
argument list (the parentheses in C<use Foo ( ... );>), or C<undef> when
there is none. A list nested inside the arguments, such as the parentheses
of a function or method call, does not qualify. Shared with
L<Perl::Critic::PJCJ::Fixer> so the policy and the fixer can never disagree
about which parentheses a "remove parentheses" violation means.

=head2 _analyse_argument_types

Analyses use/no statement arguments to classify them into different types:
fat comma operators, complex expressions, version numbers, simple strings,
and quote operators. This classification drives the quoting rule enforcement
in C<check_use_statement>.

Also detects whether the original statement uses parentheses, which affects
the violation messages for fat comma and complex expression cases.

=head2 collect_qw_words ($words, @elements)

Decodes the values of use/no statement arguments into C<$words>, recursing
into parenthesised lists. Returns false when any element cannot become a
C<qw()> word: an interpolating or escape-bearing string, a plain bareword,
an operator other than a comma, or any other expression. Shared with
L<Perl::Critic::PJCJ::Fixer>, so the policy suggests C<use qw()> exactly
when the fixer can rewrite the statement.

=head2 qw_word_ok ($word)

Tests whether a single decoded word can be written inside C<qw( )>: it must
be non-empty and free of whitespace, parentheses and backslashes. This is
the single word-representability predicate, shared with
L<Perl::Critic::PJCJ::Fixer>.

=head2 _use_args_qw_representable

Tests whether every use/no statement argument can be represented as a word
inside C<qw( )>, combining C<collect_qw_words> and C<qw_word_ok>. The
C<use qw()> suggestion is only emitted when this holds.

=head2 _use_qw_violation

Emits the C<use qw()> violation for a use/no statement, or nothing when the
arguments are not qw-representable.

=head2 _summarise_use_arguments

Detects C<qw()> usage among use/no statement arguments and whether those
C<qw()> operators use parentheses rather than other delimiters. This
information drives the violation logic in C<check_use_statement>.

=head2 check_use_statement

Checks quoting consistency in C<use> and C<no> statements. Analyses every
argument type to enforce appropriate quoting:

=over 4

=item * Version numbers are exempt from all quoting rules

=item * Fat comma arguments should have no parentheses for readability

=item * Complex expressions should have no parentheses to reduce visual noise

=item * Arguments requiring interpolation follow normal string quoting rules

=item * Simple string arguments should use C<qw()> with parentheses only

=back

This promotes consistency and clarity whilst supporting modern Perl idioms
and maintaining compatibility with tools like perlimports.

=head1 AUTHOR

Paul Johnson <paul@pjcj.net>

=head1 COPYRIGHT

Copyright 2025 Paul Johnson.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
