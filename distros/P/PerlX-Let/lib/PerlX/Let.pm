package PerlX::Let;

# ABSTRACT: Syntactic sugar for lexical constants

use v5.12;

use strict;
use warnings;

use Const::Fast ();
use Keyword::Simple;
use Text::Balanced ();

our $VERSION = 'v0.2.3';


sub import {
    Keyword::Simple::define 'let', \&_rewrite_let;
}

sub unimport {
    Keyword::Simple::undefine 'let';
}

sub _rewrite_let {
    my ($ref) = @_;

    my $let = "";

    do {

        my ( $name, $val );

        ( $name, $$ref ) = Text::Balanced::extract_variable($$ref);
        $$ref =~ s/^\s*\=>?\s*// or die;
        ( $val, $$ref ) = Text::Balanced::extract_quotelike($$ref);
        ( $val, $$ref ) = Text::Balanced::extract_bracketed( $$ref, '({[' )
          unless defined $val;

        unless ( defined $val ) {
            ($val) = $$ref =~ /^(\S+)/;
            $$ref =~ s/^\S+//;
        }

        if ($val !~ /[\$\@\%\&]/ && ($] >= 5.028 || substr($name, 0, 1) eq '$')) {

            # We can't use Const::Fast on state variables, so we use
            # this workaround.

            $let .= "use feature 'state'; state $name = $val; unless (state \$__perlx_let_state_is_set = 0) { Const::Fast::_make_readonly(\\$name); \$__perlx_let_state_is_set = 1; };";

        }
        else {

            $let .= "Const::Fast::const my $name => $val; ";
        }

    } while ( $$ref =~ s/^\s*,\s*// );

    my $code;

    ( $code, $$ref ) = Text::Balanced::extract_codeblock( $$ref, '{' );

    if ($code) {
        substr( $code, index( $code, '{' ) + 1, 0 ) = $let;
        substr( $$ref, 0, 0 ) = $code;
    }
    else {
        substr( $$ref, 0, 0 ) = $let;
    }

}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlX::Let - Syntactic sugar for lexical constants

=head1 VERSION

version v0.2.3

=head1 SYNOPSIS

  use PerlX::Let;

  let $x = 1,
      $y = "string" {

      if ( ($a->($y} - $x) > ($b->{$y} + $x) )
      {
        something( $y, $x );
      }

  }

=head1 DESCRIPTION

This module allows you to define lexical constants using a new C<let>
keyword, for example, code such as

  if (defined $arg{username}) {
    $row->update( { username => $arg{username} );
  }

is liable to typos. You could simplify it with

  let $key = "username" {

    if (defined $arg{$key}) {
      $row->update( { $key => $arg{$key} );
    }

  }

This is roughly equivalent to using

  use Const::Fast;

  {
   const $key => "username";

    if (defined $arg{$key}) {
      $row->update( { $key => $arg{$key} );
    }

  }

However, if the value does not contain a sigil, and the variable is a
scalar, or you are using Perl v5.28 or later, this uses state
variables so that the value is only set once.

If the code block is omitted, then this can be used to declare a
state constant in the current scope, e.g.

  let $x = "foo";

  say $x;

=head1 KNOWN ISSUES

The parsing of assignments is rudimentary, and may fail when assigning
to another variable or the result of a function.

Because this modifies the source code during compilation, the line
numbers may be changed.

=head1 SEE ALSO

L<Const::Fast>

L<Keyword::Simple>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
