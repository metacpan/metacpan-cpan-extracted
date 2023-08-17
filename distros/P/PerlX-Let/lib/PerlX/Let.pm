package PerlX::Let;

# ABSTRACT: Syntactic sugar for lexical state constants

use v5.12;
use warnings;

use Const::Fast ();
use Keyword::Simple 0.04;
use Text::Balanced ();

our $VERSION = 'v0.3.0';


sub import {
    Keyword::Simple::define 'let', \&_rewrite_let;
}

sub unimport {
    Keyword::Simple::undefine 'let';
}

sub _rewrite_let {
    my ($ref) = @_;

    my $let = "";

    my ( $name, $val );

    ( $name, $$ref ) = Text::Balanced::extract_variable($$ref);
    die "A variable name is required for let" unless defined $name;
    $$ref =~ s/^\s*\=>?\s*// or die "An assignment is required for let";
    ( $val, $$ref ) = Text::Balanced::extract_quotelike($$ref);
    ( $val, $$ref ) = Text::Balanced::extract_bracketed( $$ref, '({[' )
        unless defined $val;

    unless ( defined $val ) {
        ($val) = $$ref =~ /^(\S+)/;
        $$ref =~ s/^\S+//;
    }

    die "A value is required for let" unless defined $val;

    if ($val !~ /[\$\@\%\&]/ && ($] >= 5.028 || substr($name, 0, 1) eq '$')) {

        # We can't use Const::Fast on state variables, so we use this workaround.

        $let .= "use feature 'state'; state $name = $val; unless (state \$__perlx_let_state_is_set = 0) { Const::Fast::_make_readonly(\\$name); \$__perlx_let_state_is_set = 1; };";

    }
    else {

        $let .= "Const::Fast::const my $name => $val; ";
    }

    substr( $$ref, 0, 0 ) = $let;

}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PerlX::Let - Syntactic sugar for lexical state constants

=head1 VERSION

version v0.3.0

=head1 SYNOPSIS

  use PerlX::Let;

  {

      let $x = 1;
      let $y = "string";

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

  {
      let $key = "username";

      if (defined $arg{$key}) {
          $row->update( { $key => $arg{$key} );
      }

  }

This is roughly equivalent to using

  use Const::Fast ();

  {
      use feature 'state';

      state $key = "username";

      unless (state $_flag = 0) {
          Const::Fast::_make_readonly( \$key );
          $_flag = 1;
      }

      if (defined $arg{$key}) {
          $row->update( { $key => $arg{$key} );
      }

  }

However, if the value contains a sigil, or (for versions of Perl
before 5.28) the value is not a scalar, then this uses a my variable

  use Const::Fast ();

  {
      Const::Fast::const my $key => "username";

      if (defined $arg{$key}) {
          $row->update( { $key => $arg{$key} );
      }
  }

The reason for using state variables is that it takes time to mark a
variable as read-only, particularly for deeper data structures.
However, the tradeoff for using this is that the variables remain
allocated until the process exits.

=head1 KNOWN ISSUES

A let assignment will enable the state feature inside of the current
context.

The parsing of assignments is rudimentary, and may fail when assigning
to another variable or the result of a function.  Because of this,
you may get unusual error messages for syntax errors, e.g.
"Transliteration pattern not terminated".

Because this modifies the source code during compilation, the line
numbers may be changed, particularly if the let assignment(s) are on
multiple lines.

=head1 SUPPORT FOR OLDER PERL VERSIONS

The this module requires Perl v5.12 or later.

Future releases may only support Perl versions released in the last ten years.

=head1 SEE ALSO

L<feature>

L<Const::Fast>

L<Keyword::Simple>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2023 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
