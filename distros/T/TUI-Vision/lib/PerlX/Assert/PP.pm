package PerlX::Assert::PP;
# ABSTRACT: Toby Inkster's assertion keyword in pure-Perl without XS dependency

use strict;
use warnings;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:BRICKPOOL';

use Carp ();

our @EXPORT = qw( assert );

# Enables or disables the source filter for block-style assertions
use constant ASSERT_BLOCK => exists $ENV{PERLX_ASSERT_PP_FILTER} 
                                 && $ENV{PERLX_ASSERT_PP_FILTER};

use if ASSERT_BLOCK, 'B';
use if ASSERT_BLOCK, 'Filter::Simple';
use if ASSERT_BLOCK, 'Text::Balanced', qw(
  extract_quotelike
  extract_codeblock
);

# Assertions are enabled if either STRICT is true or -check was used
use constant STRICT => !!grep { exists $ENV{$_} && $ENV{$_} } qw(
  PERL_STRICT
  EXTENDED_TESTING
  AUTHOR_TESTING
  RELEASE_TESTING
);

# Debug mode
use constant DEBUG => do {
  no warnings 'uninitialized';
  0+( exists $ENV{PERLX_ASSERT_PP_DEBUG} ? $ENV{PERLX_ASSERT_PP_DEBUG} : 0 );
};

use constant {
  PHASE_MASK   => 2**0,
  PHASE_PARSE  => 2**1,
  PHASE_INJECT => 2**2,
};

our $CHECK = 0;

# -------------------------------------------------------------------------
# import / unimport
# -------------------------------------------------------------------------

sub import {
  my ( $class, @args ) = @_;
  my $caller = caller();

  # process -check flag
  $CHECK = 1 if grep { $_ eq '-check' } @args;

  # export our functions
  no strict 'refs';
  foreach ( @EXPORT ) {
    *{"${caller}::$_"} = \&$_
      unless *{"${caller}::$_"}{CODE};
  }
} #/ sub import

sub unimport {
  my ( $class ) = @_;
  my $caller = caller();

  no strict 'refs';
  foreach ( @EXPORT ) {
    undef( *{"${caller}::$_"} )
      if *{"${caller}::$_"}{CODE};
  }
}

# -------------------------------------------------------------------------
# assert EXPR;
# assert "name", EXPR;
# -------------------------------------------------------------------------

sub assert ($;$) {
  my ( $name, $bool );

  # only check when STRICT or CHECK is enabled
  return unless STRICT || $CHECK;

  if ( @_ == 2 ) {
    # two-argument form: assert NAME, BOOL
    ( $name, $bool ) = @_;
  }
  elsif ( @_ == 1 ) {
    # one-argument form: assert BOOL
    $bool = $_[0];
    $name = undef;
  }
  else {
    Carp::croak( "assert() called with invalid number of arguments" );
  }

  # assertion passes
  return if $bool;

  # assertion fails
  if ( defined $name ) {
    Carp::croak( "Assertion failed: $name" );
  }
  else {
    Carp::croak( "Assertion failed" );
  }

  return;
} #/ sub assert ($;$)

# -------------------------------------------------------------------------
# Filter entry point: mask > parse > inject + optional debug
#
# Source filter:
#   assert { BLOCK };           -> assert 'BLOCK', do { BLOCK };
#   assert "name" { BLOCK };    -> assert "name", do { BLOCK };
# -------------------------------------------------------------------------

FILTER_ONLY( executable => sub {
  my $src = $_;

  unless ( index($src, 'assert') >= 0 ) {
    DEBUG and warn("quick bailout: no 'assert'\n");
    return;
  }

  my $scan = mask_strings_and_comments( $src );
  DEBUG & PHASE_MASK and do {
    warn "=== START DEBUG MASK ===\n";
    require Text::Diff;
    my $diff = Text::Diff::diff( \$src, \$scan );
    warn "--- DIFF ---\n$diff\n";
    warn "=== END MASK DEBUG ===\n";
  };

  my $asserts = parse_asserts( $src, $scan );
  DEBUG & PHASE_PARSE and do {
    warn "=== START DEBUG PARSE ===\n";
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    warn Data::Dumper->Dump( $asserts );
    warn "=== END PARSE DEBUG ===\n";
  };

  $_ = inject_asserts( $src, $asserts );
  DEBUG & PHASE_INJECT and do {
    warn "=== START DEBUG PHASE_INJECT ===\n";
    require Text::Diff;
    my $diff = Text::Diff::diff( \$src, \$_ );
    warn "--- DIFF ---\n$diff\n";
    warn "=== END INJECT DEBUG ===\n";
  };
} ) if ASSERT_BLOCK;

# -------------------------------------------------------------------------
# Masking: masks all sections of the source string that contain 
# quotelikes and comments.
# -------------------------------------------------------------------------

sub mask_strings_and_comments {
  my ( $src ) = @_;
  my $out = '';

  while ( length $src ) {
    if ( $src =~ /(?<!\w)(["'`]|q[qwxr]?)/ ) {
      my $idx = $-[0];
      DEBUG & PHASE_MASK and do {
        warn "[MASK]: next quote-like at index $idx\n";
      };

      $out .= substr( $src, 0, $idx );

      my $tail = substr( $src, $idx );
      DEBUG & PHASE_MASK and do {
        warn "[MASK]: tail starts with: " . substr( $tail, 0, 20 ) . "\n";
      };
      my ( $str, $remainder ) = extract_quotelike( $tail );

      if ( !defined $str || $str eq '' ) {
        DEBUG & PHASE_MASK and do {
          warn "[MASK]: extract_quotelike returned undef, consuming 1 char\n";
        };
        $out .= substr( $src, $idx, 1 );
        $src = substr( $src, $idx + 1 );
        next;
      }

      DEBUG & PHASE_MASK and do {
        warn "[MASK]: extracted string: [$str]\n";
      };

      $out .= ' ' x length( $str );
      $src = $remainder;
    } #/ if ( $src =~ ...)
    else {
      $out .= $src;
      last;
    }
  } #/ while ( length $src )

  # masking all comments
  $out =~ s{(^|(?<=\s))\#.*$}{ $1 . (' ' x (length($&) - length($1))) }egm;

  return $out;
}

# -------------------------------------------------------------------------
# Parsing: find all assert block statements and save them as metadata.
#
# The $src parameter contains the original code and the $scan parameter 
# contains a modified source code where strings and comments have been 
# masked to prevent their content from being parsed.
#
# Returns a list of HashRef's:
#   { start => Int, length => Int, name => Str|undef, block => Str }
# -------------------------------------------------------------------------

sub parse_asserts {
  my ( $src, $scan ) = @_;

  my @asserts;

  # Initialize parsing position
  pos( $src ) = 0;

  while ( 1 ) {

    # Find next occurrence of 'assert' in the scan string,
    my $idx = index( $scan, "assert", pos( $src ) );
    last if $idx == -1;

    DEBUG & PHASE_PARSE and do {
      warn "[PARSE]: found 'assert' in scan at offset $idx\n";
    };

    # Move source position to the start of this assert
    pos( $src ) = $idx;

    # Consume the keyword 'assert' including trailing whitespace
    $src =~ /\Gassert\s*/gc
      or next;    # should not happen, but keeps parser robust

    # Try to read an optional NAME (string-producing quotelike)
    my ( $name ) = extract_quotelike( $src );

    # Check whether a quote-like has been found and verify it.
    if ( defined $name ) {
      # 'qw', 'qx', or 'qr' are not valid for NAME -> skip it
      next if $name =~ /\Aq[wxr]\b/;

      DEBUG & PHASE_PARSE and do {
        warn "[PARSE]: assert NAME in source: $name\n";
      };

      # Skip whitespace after NAME
      $src =~ /\G\s*/gc;
    }

    # Extract the code block
    my ( $block ) = extract_codeblock( $src );

    # If no block is found, this is not a valid assert -> skip it
    unless ( defined $block ) {
      DEBUG & PHASE_PARSE and do {
        warn "[PARSE]: extraction failed at offset ". pos( $src ) . "\n";
      };
      next;
    }

    # Determine the full length of the entire statement
    my $length = pos( $src ) - $idx;

    DEBUG & PHASE_PARSE and do {
      warn "[PARSE]: found { BLOCK } in scan at offset " . 
        ( pos( $src ) - length( $block ) ) . "\n";
      warn "[PARSE]: assert statement length: $length\n";
    };

    # At this point:
    # - $name is undef or a valid string NAME
    # - $block contains the full { ... } block
    # - $length contains the statement length w/o optional ';'
    # - pos($src) is behind the block

    push @asserts, {
      start  => $idx,
      length => $length,
      name   => $name,
      block  => $block,
    };

    # Continue searching for the next assert
  } #/ while ( 1 )

  return \@asserts;
} #/ sub parse_asserts

# -------------------------------------------------------------------------
# Injection: build a new string with replacements for the block based 
# assert statements.
# -------------------------------------------------------------------------

sub inject_asserts {
  my ( $src, $asserts ) = @_;

  my $out = '';
  my $pos = 0;

  foreach ( @$asserts ) {

    my $off   = $_->{start};        # start offset of the statement
    my $len   = $_->{length};       # full length of the statement
    my $name  = $_->{name};         # includes quote likes string or 'undef'
    my $block = $_->{block};        # includes outer braces

    # Overwrite the parameters if neither STRICT nor CHECK is enabled.
    unless ( $CHECK || STRICT ) {
      $name = "undef";
      $block = "{ 1 }";
    }

    DEBUG & PHASE_INJECT and do {
      warn "[INJECT]: inject at offset $off\n";
    };

    # copy everything before this assert block
    $out .= substr( $src, $pos, $off - $pos );

    # generate name if missing
    unless ( defined $name ) {
      $name = do {
        # Quote { BLOCK } as Perl string literal
        local $_ = $block;
        s/#.*$//gm;      # remove comments
        s/\s{2,}/ /g;    # replace any white spaces with one space
        B::perlstring( $_ );
      };
      DEBUG & PHASE_INJECT and do {
        warn "[INJECT]: generated name: $name\n";
      };
    }

    # build injected code
    my $injected = "assert $name, do $block";

    DEBUG & PHASE_INJECT and do {
      warn "[INJECT]: injected code: $injected\n";
    };

    $out .= $injected;

    # move cursor after the original block
    $pos = $off + $len;
  } #/ foreach my $a ( @$asserts )

  # append remaining source
  $out .= substr( $src, $pos );

  return $out;
}

1

__END__

=head1 NAME

PerlX::Assert::PP - Pure Perl assert keyword as a drop-in sub for PerlX::Assert

=head1 SYNOPSIS

  use PerlX::Assert::PP -check;

  # Basic anonymous assertion:
  assert { $value > 0 };

  # Named assertion:
  assert "value must be positive" { $value > 0 };

  # Assertions are active if -check is used or if one of the following
  # environment variables is set:
  #
  #   PERL_STRICT
  #   EXTENDED_TESTING
  #   AUTHOR_TESTING
  #   RELEASE_TESTING
  #
  # Example:
  #   $ PERL_STRICT=1 perl script.pl

=head1 DESCRIPTION

C<PerlX::Assert::PP> provides a lightweight, pure-Perl assertion mechanism
inspired by L<PerlX::Assert>. It supports the following assertion forms:

  assert EXPR;
  assert { BLOCK };
  assert "name", EXPR;
  assert "name" { BLOCK };

A named assertion includes its name in the error message on failure. Anonymous
assertions are automatically I<deparsed>, producing a compact representation of 
the failing code.

Assertions are enabled when either the C<-check> import flag is used or when one
of the environment variables listed above is set. This makes it easy to enable
assertions in development, CI, or testing, while keeping them disabled in
production.

=head1 FILTER BEHAVIOUR

The environment variable C<PERLX_ASSERT_PP_FILTER> enables or disables a 
source filter for block-style assertions.

By default, C<PerlX::Assert::PP> operates in a fast, lightweight mode:
only the expression-style assertions are supported:

  assert EXPR;
  assert "name", EXPR;

In this mode, no source filter is loaded. This avoids the compile-time
overhead associated with C<Filter::Simple> and C<Text::Balanced>, and is
suitable for large code bases or performance-sensitive environments.

If the environment variable C<PERLX_ASSERT_PP_FILTER> is set to a true
value, the module activates its source filter. This enables the block
assertion syntax:

  assert { BLOCK };
  assert "name" { BLOCK };

When enabled, block assertions are rewritten at compile time into:

  assert "name", do { BLOCK };

Only executable code is scanned (C<FILTER_ONLY executable>). Strings and
comments are masked beforehand so that occurrences of the word C<assert> within
them are never touched, matched, or executed.

The filter relies on L<Text::Balanced> to extract one quoted assertion name
(C<''>, C<"">, C<q(...)>, or C<qq(...)>) and one balanced block C<{ ... }>.
Nested blocks are fully supported. Quote-like operators such as C<qw(...)>,
C<qr(...)>, C<qx(...)>, C<s///>, and C<m//> are intentionally not treated as
assertion names.

The filter is robust for normal Perl code, including nested blocks and
structures. However, as with all source filters, complex quoting constructs,
macro-like expansions, or heavy syntax extensions may cause unexpected
behaviour. If a stable, filter-free solution is required, consider using the
original XS-based L<PerlX::Assert> by Toby Inkster.

B<Note>: that enabling the filter introduces additional compile-time cost,
because the filter inspects and rewrites the source code. For this
reason, it is disabled by default.

Examples:

  $ perl script.pl                            # fast mode, no block assertions
  $ PERLX_ASSERT_PP_FILTER=1 perl script.pl   # block assertions supported

=head1 LIMITATIONS

The original L<PerlX::Assert> uses L<Exporter::Tiny> and provides a highly
flexible import system. This pure-Perl implementation instead exports C<assert>
directly into the caller's namespace and performs a compile-time source rewrite.

The assertion name must be a single-quoted string, a double-quoted string, or a
C<q(...)>/C<qq(...)> expression. Other quote-like operators (C<qr>, C<qx>,
C<qw>, C<s///>, C<m//>, etc.) are not treated as assertion names.

Assertions are implemented as normal subroutine calls. The call itself cannot 
be eliminated. However, if assertions are disabled, the block is not evaluated 
in block syntax and the overhead is minimal. In expression syntax, however, the 
expression is evaluated completely before it is passed to the assert subroutine.

=head1 REQUIRES

=over 4

=item *

L<B> 

=item *

L<Carp> 

=item *

L<Filter::Simple> 

=item *

L<Text::Balanced> 

=back

=head1 SEE ALSO

=over 4

=item *

L<PerlX::Assert>

=item *

L<Devel::Assert>.

=back

=head1 AUTHOR

J. Schneider <brickpool@cpan.org>

=head1 CONTRIBUTOR

Toby Inkster <tobyink@cpan.org>

=head1 LICENSE

Copyright (c) 2013-2014, 2026 the L</AUTHOR> and L</CONTRIBUTOR> listed above.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
