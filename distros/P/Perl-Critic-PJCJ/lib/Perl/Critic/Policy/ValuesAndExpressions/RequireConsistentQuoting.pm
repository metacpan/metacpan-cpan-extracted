package Perl::Critic::Policy::ValuesAndExpressions::RequireConsistentQuoting v0.1.2;

use v5.26.0;
use strict;
use warnings;
use feature      qw( signatures );
use experimental qw( signatures );

use List::Util          qw( any );
use Perl::Critic::Utils qw( $SEVERITY_MEDIUM );
use parent              qw( Perl::Critic::Policy );

my $Desc         = "Quoting";
my $Expl_double  = 'use ""';
my $Expl_single  = "use ''";
my $Expl_optimal = "use %s";
my $Expl_use_qw  = "use qw()";

sub supported_parameters { }
sub default_severity     { $SEVERITY_MEDIUM }
sub default_themes       { qw( cosmetic ) }

sub applies_to { qw(
  PPI::Token::Quote::Single
  PPI::Token::Quote::Double
  PPI::Token::Quote::Literal
  PPI::Token::Quote::Interpolate
  PPI::Token::QuoteLike::Words
  PPI::Token::QuoteLike::Command
  PPI::Statement::Include
) }

sub would_interpolate ($self, $string) {
  # This is the authoritative way to check - let PPI decide
  my $test_content = qq("$string");
  my $test_doc     = PPI::Document->new(\$test_content);

  my $would_interpolate = 0;
  $test_doc->find(
    sub ($top, $test_elem) {
      $would_interpolate = $test_elem->interpolations
        if $test_elem->isa("PPI::Token::Quote::Double");
      0
    }
  );

  $would_interpolate
}

sub delimiter_preference_order ($self, $delimiter_start) {
  return 0 if $delimiter_start eq "(";
  return 1 if $delimiter_start eq "[";
  return 2 if $delimiter_start eq "<";
  return 3 if $delimiter_start eq "{";
  99
}

sub parse_quote_token ($self, $elem) {
  my $content = $elem->content;

  # Handle all possible delimiters, not just bracket pairs
  # Order matters: longer matches first
  if ($content =~ /\A(qw|qq|qx|q)\s*(.)(.*)\z/s) {
    my ($op, $start_delim, $rest) = ($1, $2, $3);
    my $end_delim = $start_delim;

    $end_delim
      = $start_delim eq "(" ? ")"
      : $start_delim eq "[" ? "]"
      : $start_delim eq "{" ? "}"
      : $start_delim eq "<" ? ">"
      :                       $start_delim;
    # Non-bracket delimiters use same char for start/end

    $rest =~ s/\Q$end_delim\E\z//;

    ($start_delim, $end_delim, $rest, $op)
  }
}

sub _get_supported_delimiters ($self, $operator) {
  return (
    {
      start   => "(",
      end     => ")",
      display => "${operator}()",
      chars   => [ "(", ")" ],
    }, {
      start   => "[",
      end     => "]",
      display => "${operator}[]",
      chars   => [ "[", "]" ],
    }, {
      start   => "<",
      end     => ">",
      display => "${operator}<>",
      chars   => [ "<", ">" ],
    }, {
      start   => "{",
      end     => "}",
      display => "${operator}{}",
      chars   => [ "{", "}" ],
    }
  );
}

sub find_optimal_delimiter (
  $self, $content,
  $operator      = "qw",
  $current_start = "",
  $current_end   = "",
) {
  my @delimiters = $self->_get_supported_delimiters($operator);

  for my $delim (@delimiters) {
    my $count = 0;
    for my $char ($delim->{chars}->@*) {
      $count += () = $content =~ /\Q$char\E/g;
    }
    $delim->{count} = $count;
  }

  my $min_count = (sort { $a <=> $b } map { $_->{count} } @delimiters)[0];

  # Find optimal delimiter: handle unbalanced content, then preference order
  my ($optimal) = sort {
    $a->{count} <=> $b->{count} ||  # Handle unbalanced first
      $self->delimiter_preference_order($a->{start}) <=>  # Then prefer by order
      $self->delimiter_preference_order($b->{start})
  } @delimiters;

  my $current_is_bracket = 0;
  my $current_delim;
  for my $delim (@delimiters) {
    if ($delim->{start} eq $current_start && $delim->{end} eq $current_end) {
      $current_delim      = $delim;
      $current_is_bracket = 1;
      last;
    }
  }

  my $current_is_optimal = 0;
  $current_is_optimal = ($current_delim eq $optimal)
    if $current_is_bracket && $current_delim;

  ($optimal, $current_is_optimal)
}

sub check_delimiter_optimisation ($self, $elem) {
  my ($current_start, $current_end, $content, $operator)
    = $self->parse_quote_token($elem);

  return unless defined $current_start;

  my ($optimal_delim, $current_is_optimal)
    = $self->find_optimal_delimiter($content, $operator, $current_start,
      $current_end);

  return $self->violation($Desc,
    sprintf($Expl_optimal, $optimal_delim->{display}), $elem)
    if !$current_is_optimal;

  undef
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

  my $class      = ref $elem;
  my $method     = $dispatch->{$class} or return;
  my @violations = grep { defined } $self->$method($elem);
  @violations
}

sub _choose_optimal_quote_style ($self, $elem, $string, $has_single_quotes,
  $has_double_quotes, $would_interpolate,)
{
  # Has both quote types - q() handles this cleanly
  return $self->check_delimiter_optimisation($elem)
    if $has_single_quotes && $has_double_quotes;

  if ($has_single_quotes) {
    return $would_interpolate
      ? $self->check_delimiter_optimisation($elem)
      : $self->violation($Desc, $Expl_double, $elem);
  }

  if ($has_double_quotes) {
    return $would_interpolate
      ? $self->check_delimiter_optimisation($elem)
      : $self->violation($Desc, $Expl_single, $elem);
  }

  return $self->violation($Desc, $Expl_single, $elem) if $would_interpolate;

  $self->violation($Desc, $Expl_double, $elem)
}

sub check_single_quoted ($self, $elem) {
  return if $self->_is_in_use_statement($elem);
  my $string  = $elem->string;
  my $content = $elem->content;

  # Special case: strings with newlines don't follow the rules
  return if $self->_has_newlines($string);

  # Rules 1,2: Use double quotes unless string has literal $/@ or double quotes
  return if index($string, '"') != -1;

  # Escaped single quotes suggest double quotes
  return $self->violation($Desc, $Expl_double, $elem) if $content =~ /\\'/;

  my $would_interpolate = $self->would_interpolate($string);

  # Check if string contains escape sequences that would have different meanings
  # between single vs double quotes. If so, preserve single quotes.
  return if $self->_has_dangerous_escape_sequences($string);

  # Literal \$ and \@ would change meaning in double quotes
  return if $self->_has_literal_escape_sigils($string);

  return $self->violation($Desc, $Expl_double, $elem)
    if !$would_interpolate && index($string, '"') == -1;

  return
}

sub check_double_quoted ($self, $elem) {
  return if $self->_is_in_use_statement($elem);

  my $string  = $elem->string;
  my $content = $elem->content;

  # Special case: strings with newlines don't follow the rules
  return if $self->_has_newlines($string);

  # Check for escaped dollar/at signs or double quotes, but only suggest single
  # quotes if no other interpolation exists
  return $self->violation($Desc, $Expl_single, $elem)
    if $content =~ /\\[\$\@\"]/ && !$self->would_interpolate($string);

  return
}

sub check_q_literal ($self, $elem) {
  return if $self->_is_in_use_statement($elem);

  my $string = $elem->string;

  # Special case: strings with newlines don't follow the rules
  return if $self->_has_newlines($string);

  # Preserve q() for escape sequences, optimize delimiter
  return $self->check_delimiter_optimisation($elem)
    if $self->_has_dangerous_escape_sequences($string);

  # Preserve q() for literal \$ or \@, optimize delimiter
  return $self->check_delimiter_optimisation($elem)
    if $self->_has_literal_escape_sigils($string);

  my $has_single_quotes = index($string, "'") != -1;
  my $has_double_quotes = index($string, '"') != -1;
  my $would_interpolate = $self->would_interpolate($string);

  $self->_choose_optimal_quote_style($elem, $string, $has_single_quotes,
    $has_double_quotes, $would_interpolate)
}

sub check_qq_interpolate ($self, $elem) {
  return if $self->_is_in_use_statement($elem);

  my $string = $elem->string;

  # Special case: strings with newlines don't follow the rules
  return if $self->_has_newlines($string);

  # Only preserve qq() if escape sequences are actually needed
  return $self->check_delimiter_optimisation($elem)
    if $self->_has_dangerous_escape_sequences($string);

  my $double_quote_suggestion
    = $self->_what_would_double_quotes_suggest($string);

  # Rules 1,2: If double quotes would suggest single quotes, use single quotes
  if ($double_quote_suggestion && $double_quote_suggestion eq "''") {
    # qq() is only justified if it handles double quotes cleanly
    return if index($string, '"') != -1;
    return $self->violation($Desc, $Expl_single, $elem);
  }

  # Rule 1: If double quotes would suggest qq(), qq() is appropriate
  return $self->check_delimiter_optimisation($elem)
    if $double_quote_suggestion && $double_quote_suggestion eq "qq()";

  # Rule 1: Otherwise prefer simple double quotes unless delimiter chars present
  my $has_special_chars
    = index($string, '"') != -1
    || index($string, "'") != -1
    || $self->would_interpolate($string);

  $has_special_chars
    ? $self->check_delimiter_optimisation($elem)
    : $self->violation($Desc, $Expl_double, $elem)
}

sub check_quote_operators ($self, $elem) {
  return if $self->_is_in_use_statement($elem);

  my ($current_start, $current_end, $content, $operator)
    = $self->parse_quote_token($elem);
  return unless defined $current_start;

  # Don't skip empty content - () is preferred even for empty quotes
  my ($optimal_delim, $current_is_optimal)
    = $self->find_optimal_delimiter($content, $operator, $current_start,
      $current_end);

  return $self->violation($Desc,
    sprintf($Expl_optimal, $optimal_delim->{display}), $elem)
    if !$current_is_optimal;

  return
}

sub check_use_statement ($self, $elem) {
  # Only check 'use' statements, not 'require' or 'no'
  return unless $elem->type eq "use";

  my @args = $self->_extract_use_arguments($elem) or return;

  my ($string_count, $has_qw, $qw_uses_parens)
    = $self->_analyze_use_arguments(@args);
  $self->_check_use_violations($elem, $string_count, $has_qw, $qw_uses_parens,
    @args)
}

sub _extract_use_arguments ($self, $elem) {
  my @children     = $elem->children;
  my $found_module = 0;
  my @args;

  for my $child (@children) {
    if ($child->isa("PPI::Token::Word") && !$found_module) {
      next if $child->content eq "use";
      # This is the module name
      $found_module = 1;
      next;
    }

    if ($found_module) {
      next if $child->isa("PPI::Token::Whitespace");
      next if $child->isa("PPI::Token::Structure") && $child->content eq ";";
      push @args, $child;
    }
  }

  @args
}

sub _analyze_use_arguments ($self, @args) {
  my $string_count   = 0;
  my $has_qw         = 0;
  my $qw_uses_parens = 1;

  for my $arg (@args) {
    $self->_count_use_arguments($arg, \$string_count, \$has_qw,
      \$qw_uses_parens);
  }

  ($string_count, $has_qw, $qw_uses_parens)
}

sub _check_use_violations ($self, $elem, $string_count, $has_qw,
  $qw_uses_parens, @args,)
{
  return $self->violation($Desc, $Expl_use_qw, $elem)
    if ($has_qw && !$qw_uses_parens)             # qw() without parens
    || ($has_qw && $string_count > 0)            # Mixed qw() and quotes
    || ($string_count > 1 && !$has_qw)           # Multiple strings
    || (
      $string_count == 1 && !$has_qw &&          # Single quotes
      any { $_->isa("PPI::Token::Quote::Single") } @args
    );

  ()
}

sub _count_use_arguments ($self, $elem, $string_count_ref, $has_qw_ref,
  $qw_uses_parens_ref,)
{

  $$string_count_ref++
    if $elem->isa("PPI::Token::Quote::Single")
    || $elem->isa("PPI::Token::Quote::Double")
    || $elem->isa("PPI::Token::Quote::Literal")
    || $elem->isa("PPI::Token::Quote::Interpolate");

  if ($elem->isa("PPI::Token::QuoteLike::Words")) {
    $$has_qw_ref = 1;
    my $content = $elem->content;
    $$qw_uses_parens_ref = 0 if $content !~ /\Aqw\s*\(/;
  }

  # Recursively check children (for structures like lists)
  if ($elem->can("children")) {
    for my $child ($elem->children) {
      $self->_count_use_arguments($child, $string_count_ref, $has_qw_ref,
        $qw_uses_parens_ref);
    }
  }
}

sub _is_in_use_statement ($self, $elem) {
  my $current = $elem;
  while ($current) {
    return 1
      if $current->isa("PPI::Statement::Include") && $current->type eq "use";
    $current = $current->parent;
  }
  0
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
    return "''"   if !$has_single_quotes; # Only double quotes, no interpolation
  }

  # Rules 1,2: Otherwise double quotes are fine
  undef
}

sub _has_dangerous_escape_sequences ($self, $string) {
  # Check if string contains escape sequences that would have different meanings
  # in single vs double quotes. These should be preserved in their current
  # quote style to maintain their intended meaning.
  #
  # This only includes escape sequences where the conversion would change
  # the actual output, not just the internal representation.
  $string =~ /
    \\(?:
      [tnrfbae]           |  # Single char escapes: \t \n \r \f \b \a \e
      x[0-9a-fA-F]*       |  # Hex escapes: \x1b \xff
      x\{[^}]*\}          |  # Hex braces: \x{1b} \x{263A}
      [0-7]{1,3}          |  # Octal: \033 \377
      o\{[^}]*\}          |  # Octal braces: \o{033}
      c.                  |  # Control chars: \c[ \cA
      N\{[^}]*\}             # Named chars: \N{name} \N{U+263A}
    )
  /x
}

sub _has_literal_escape_sigils ($self, $string) {
  # Check if string contains literal \$ or \@ that would have different
  # meanings between single and double quotes when converting FROM
  # single quotes TO double quotes (not the other direction).
  $string =~ /\\[\$\@]/
}

sub _has_newlines ($self, $string) {
  # Check if string contains literal newlines (not \n escape sequences)
  index($string, "\n") != -1
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

version v0.1.2

=head1 SYNOPSIS

  # Bad examples:
  my $greeting = 'hello';                 # use double quotes for simple strings
  my @words    = qw{word(with)parens};    # use qw[] for unbalanced content
  my $text     = qq(simple);              # use "" instead of qq()
  my $file     = q!path/to/file!;         # use "" instead of q()

  # Good examples:
  my $greeting = "hello";                 # double quotes for simple strings
  my @words    = qw[ word(with)parens ];  # optimal delimiter choice
  my $text     = "simple";                # "" preferred over qq()
  my $file     = "path/to/file";          # "" reduces punctuation

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

=head2 Special Case: Use statements

Use statements have special quoting requirements for their import lists:

=over 4

=item * Modules with no arguments or empty parentheses are acceptable

=item * Modules with one argument may use double quotes C<""> or C<qw( )>

=item * Modules with multiple arguments must use C<qw( )> with parentheses only

=back

This allows for compatibility with
L<perlimports|https://metacpan.org/pod/perlimports>.

  # Good
  use Foo;                                # no arguments
  use Bar ();                             # empty parentheses
  use Baz "single_arg";                   # one argument with double quotes
  use Qux qw( single_arg );               # one argument with qw()
  use Quux qw( arg1 arg2 arg3 );          # multiple arguments with qw()

  # Bad
  use Foo 'single_arg';                   # single quotes not allowed
  use Bar "arg1", "arg2";                 # multiple arguments need qw()
  use Baz qw[ arg1 arg2 ];                # qw() must use parentheses only
  use Qux qw{ arg1 arg2 };                # qw() must use parentheses only

=head2 Special Case: Newlines

Strings containing newlines do not follow the rules.  But note that outside of a
few very special cases, strings with literal newlines are not a good idea.

  # Allowed
  my $text = qq(
    line 1
    line 2
  );

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
  my $email    = "user@domain.com";       # Rule 2: should use single quotes
                                          # (literal @)
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

=head2 Use Statement Examples

  # Bad
  use Foo 'single_arg';                   # single quotes not allowed
  use Bar "arg1", "arg2";                 # multiple args need qw()
  use Baz qw[ arg1 arg2 ];                # qw() must use parentheses
  use Qux qw{ arg1 arg2 arg3 };           # qw() must use parentheses

  # Good
  use Foo;                                # no arguments allowed
  use Bar ();                             # empty parentheses allowed
  use Baz "single_arg";                   # one argument with double quotes
  use Qux qw( single_arg );               # one argument with qw()
  use Quux qw( arg1 arg2 arg3 );          # multiple arguments with qw() only

=head1 METHODS

=head2 supported_parameters

This policy has no configurable parameters.

=head2 violates

The main entry point for policy violation checking. Uses a dispatch table to
route different quote token types to their appropriate checking methods. This
design allows for efficient handling of the six different PPI token types that
represent quoted strings and quote-like operators.

=head2 would_interpolate

Determines whether a string would perform variable interpolation if placed in
double quotes. This is critical for deciding between single and double quotes -
strings that would interpolate variables should use single quotes to preserve
literal content, while non-interpolating strings should use double quotes for
consistency.

Uses PPI's authoritative parsing to detect interpolation rather than regex
patterns, ensuring accurate detection of complex cases like literal variables.

=head2 delimiter_preference_order

Establishes the preference hierarchy for bracket delimiters when multiple
options handle the content equally well. The policy prefers
delimiters in this order: C<()> > C<[]> > C<< <> >> > C<{}>.

This ordering balances readability and convention - parentheses are most
familiar and commonly used, while braces are often reserved for hash
references and blocks.

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
delimiters work equally well, uses the preference order to break ties.

=head2 check_delimiter_optimisation

Validates that quote-like operators use optimal delimiters according to Rules 1
and 3. This method coordinates parsing the current token and finding the
optimal alternative, issuing violations when the current choice is suboptimal.

Acts as a bridge between the parsing and optimisation logic, providing a
clean interface for the quote-checking methods.

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
intended literal content.

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

=head2 check_use_statement

Checks quoting consistency in C<use> statements. Enforces that single-argument
use statements should use double quotes rather than C<qw()>, and that
multi-argument use statements should always use C<qw()>. This promotes
consistency and clarity in module import statements.

=head1 AUTHOR

Paul Johnson C<< <paul@pjcj.net> >>

=head1 COPYRIGHT

Copyright 2025 Paul Johnson.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
