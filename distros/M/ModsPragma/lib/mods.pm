# $Id: mods.pm 1.11 Fri, 12 Sep 1997 23:21:20 -0400 jesse $

package mods;
use strict;
use integer;
use vars qw($VERSION);

# $Format: "$VERSION='$modsRelease$';"$
$VERSION='0.004';

# $list: undef ~ use Foo; [] ~ use Foo(); [...] ~ use Foo (...)
sub sim_use($$;$$) {
  my ($callpack, $pkg, $un, $list)=@_;
  my $filename=$pkg;
  $filename =~ s!::!/!g;
  require "$filename.pm";
  unless ($list and not @$list) { # Null import: use Foo ();
    # Black magic commencing. Yes there is a reason for all this fuss...
    my $meth=($un ? 'unimport' : 'import');
    no strict qw(refs);
    local (*{"${callpack}::__FNORD__"})=
      eval "package $callpack; sub {\$pkg->\$meth(\@\$list)}";
    &{"${callpack}::__FNORD__"}();
  }
}

sub import {
  my ($class, @in)=@_;
  if (@in==1 and $in[0] !~ /[^0-9.]/) {
    if ($VERSION < $in[0]) {
      require Carp;
      Carp::croak "mods $in[0] requested, only have $VERSION";
    } else {
      return;
    }
  }
  my $callpack=caller;
  my $in=join "\n", @in;
  unless ($in =~ s/^\s*~//) {
    # Defaults.
    sim_use $callpack, q(strict);
    sim_use $callpack, q(integer);
    sim_use $callpack, q(vars), 0,
    [qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @EXPORT_FAIL $AUTOLOAD $VERSION)];
  }
  # Custom.
  $in =~ s/(^|\s)\#.*$/$1/gm;	# Comments.
  while ($in =~ m{
		  (		# Import directive
		   (!)?		# Unimport?
		   \s*
		   ([\w:]+)	# Package name
		   \s*
		   (		# Import list, maybe none
		    \(
		    ( [^()]* )	# Imports themselves
		    \)
		   )?
		  ) |
		  (		# BEGIN directive
		   \{
		   ([^{}]*)	# Actual code
		   \}
		  ) |
		  (		# Export directive
		   <
		   ([^<>]*)	# Exportables
		   >
		  ) |
		  (		# Inherit
		   \[
		   ([^][]*)	# Superclasses
		   \]
		  ) |
		  (
		   [\$\@\%] \w+	# Variable
		  )
		 }sgx) {
    if ($1) {
      # Importation
      my ($un, $pack, $list, $sublist)=($2, $3, $4, $5);
      sim_use $callpack, $pack, $un, ($list ? [$sublist =~ /([^\s,]+)/g] : undef);
    } elsif ($6) {
      # Compile code
      no strict;
      no integer;
      eval "package $callpack; $7";
    } elsif ($8) {
      # Exporting
      my @what=($9 =~ /([^\s,]+)/g);
      sim_use $callpack, q(Exporter), 0, [];
      no strict qw(refs);
      push @{"${callpack}::ISA"}, q(Exporter)
	unless grep {$_ eq q(Exporter)} @{"${callpack}::ISA"};
      foreach (@what) {
	my $where=(s/!$// ? 'EXPORT' : 'EXPORT_OK');
	push @{"${callpack}::$where"}, $_;
      }
      sim_use $callpack, q(vars), 0, [grep {/^[\$\@\%]/} @what];
    } elsif ($10) {
      # Inheritance
      no strict qw(refs);
      push @{"${callpack}::ISA"}, ($11 =~ /([\w:]+)/g);
    } elsif ($12) {
      # Variable
      sim_use $callpack, q(vars), 0, [$12];
    }				# Else comment.
  }
}

1;
__END__

=head1 NAME

B<mods> - easy one-stop module shopping

=head1 SYNOPSIS

 use mods;   # Various defaults.

 use mods qw(SomePkg Other::Pkg(somefunc, $somevar));
 somefunc($somevar);

 use mods qw(foo bar());    # No imports from bar.pm; default from foo.pm.

More options:

 use mods q{
   diagnostics,     # Integral comments! Commas optional.
   Foo (bar, baz)   # Whitespace ignored.
   Quux   Jolt();   # As you think.
   vars (	    # Multilines fine.
	 $foo, $bar, $baz
	)
   !strict(refs)    # Unimport.
   $foo, $bar;      # Alternate declaration of vars.
   {$bar=7}	    # Compile-time code.
   <this, $that, @theother!> # Export; &this and $that optional.
   [Foo, Bar::Baz]  # Inherit from these.
 };

=head1 DESCRIPTION

This pragmatic module is intended as a way to reduce clutter in the prologue of a
typical OO module, which often contains a large number of repetitive
directives. Encouraging a clean programming style is the intent.

Each import-syntax item in the argument corresponds to a module to be imported. Usage
is very similar to normal B<use> statements: no extra arguments runs a default
importation; empty parens bypass importation; and arguments within parens, assumed to
be literal and separated by commas and/or whitespace, imports those items. An
exclamation point before the statement does an unimportation, like the B<no>
keyword. Note that both standard modules and compiler pragmas are supported.

Code inside braces is evaluated at compile time, as if it were inside a B<BEGIN> block.

Words inside angle brackets are taken to be things to be exported with the B<Exporter>
module (which is loaded for you, and your B<@ISA> appropriately extended). They are
placed in B<@EXPORT_OK>, or B<@EXPORT> if you append an exclamation point. If variables
(vs. functions), they are declared as globals for you.

Words inside square brackets declare superclasses: they append to B<@ISA>.

Variable names (scalar, array or hash) alone predeclare the variable, as with B<vars>.

"#" introduces comments until end-of-line. If multiple arguments are received, they are
first joined together as you would expect.

=head1 DEFAULTS

Without you needing to specify it, B<mods> automatically:

=over 4

=item *

Uses B<strict>.

=item *

Uses B<integer>.

=item *

Declares some common package variables for you (with B<vars>): B<@ISA>, B<@EXPORT>,
B<@EXPORT_OK>, B<%EXPORT_TAGS>, B<@EXPORT_FAIL>, B<$AUTOLOAD>, and B<$VERSION>.

=back

If any of these defaults causes a problem in your module which cannot be trivially
reversed, precede all other directives by a tilde (C<~>) to suppress them.

=head1 BUGS

Implementation of B<sim_use> workhorse function is incomprehensible to the author.

=head1 AUTHORS

Jesse Glick, B<jglick@sig.bsh.com>

=head1 REVISION

X<$Format: "F<$Source$> last modified $Date$ release $modsRelease$. $Copyright$"$>
F<mods/lib/mods.pm> last modified Fri, 12 Sep 1997 23:21:20 -0400 release 0.004. Copyright (c) 1997 Strategic Interactive Group. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
