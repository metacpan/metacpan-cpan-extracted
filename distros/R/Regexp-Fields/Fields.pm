#
# Regexp/Fields.pm
#
# $Author: grazz $
# $Date: 2003/10/23 18:23:57 $
#

package Regexp::Fields;
our $VERSION = '0.046';

use constant LOCALIZE_HH => 0x00020000;
use XSLoader;

XSLoader::load(__PACKAGE__, $VERSION);
install();

unless (RE_FIELDS_MAGIC()) {
    require Regexp::Fields::tie;
}

sub import {
    shift;
    return unless @_;
    $^H{"Regexp::Fields"} |= hints(@_);
    $^H |= LOCALIZE_HH;
}

sub unimport {
    shift;
    return unless @_;
    $^H{"Regexp::Fields"} &= ~hints(@_);
    $^H |= LOCALIZE_HH;
}

my %hints = (
    my   => 01,
    copy => 02
);

sub hints {
    my $h = 0;
    foreach (@_) {
	unless (exists $hints{$_}) {
	    require Carp;
	    Carp::croak("Unknown Regexp::Fields directive '$_'");
	}
	$h |= $hints{$_};
    }
    $h;
}

1;
__END__

=head1 NAME

Regexp::Fields - named capture groups

=head1 SYNOPSIS

  use Regexp::Fields qw(my);
  use strict;

  my $rx = qr/Time: (?<hrs>..):(?<min>..):(?<sec>..)/;
  if (/$rx/) {
      print "The time was: $&{hrs}:$&{min}:$&{sec}\n";
      # or: "The time was: $hrs:$min:$sec\n";
      # or: "The time was: $1:$2:$3\n";
  }

=head1 DESCRIPTION

C<Regexp::Fields> adds the extended C<< (?<name> ...) >> pattern to 
Perl's regular expression language.  This works like an ordinary pair
of capturing parens, but after a match you can use C<$&{name}>
instead of C<$1> (or whichever C<$N>) to get at the captured substring.

The C<%{&}> hash is global, like all punctuation variables.  Like C<$1>
and friends, it's dynamically scoped and bound to the "last match".

=head2 This looks familiar

The syntax is borrowed from the .NET regex library.

Differences from .NET include the following:

=over 4

=item

Regexp::Fields ignores whitespace between the field name and the
subpattern.  To match leading whitespace, you'll need to use backslash
or a character class.

  /(?<space> [ ])/;   # matches one space

=item

The digit variables aren't reordered.

  "12" =~ /(?<one>1)(2)/;    # $2 is "2"

=item

Regexp::Fields doesn't support named backreferences (which are on the
TODO list) or field names in conditional tests (which aren't).

=back

=head2 Lexical variables and the C<my> pragma

When a regex is compiled with C<use Regexp::Fields 'my'> in effect,
a lexical variable for each field will be implicitly declared.  After
a successful match the variables will be set to the captured substrings,
just like the corresponding values of C<%{&}>.  After a failed match
attempt they'll always be C<undef>.

This is not the case with C<%{&}> or the digit variables.  After a 
failed match, those might refer to a regex in some other part of
your program.  The lexical match variables work differently because
they are bound once and forever to the regex where they were declared.

  use Regexp::Fields qw(my);

  my $f = qr/(?<foo> foo)/;         # implicitly: my $foo
  my $b = qr/(?<bar> bar)/;         # implicitly: my $bar

  if (/$f/ and /$b/) {              # now $1 is "bar"
    print "Matched $foo and $bar";  # but $foo and $bar are both set!
  }

Which has some advantages, but comes with new drawbacks of its own.

First of all, Perl's lexical variables aren't visible until the 
statement after they're declared.  This means you can't use the
lexical "field" variables in C<(?{...})> or C<(??{...})> blocks,
or on the replacement side of C<s///>.

Second, this wouldn't have done the Right Thing:

  # [initialize $f and $b as above]

  if (/$f|$b/) {                 # WRONG
    print "Matched $f or $b";  
  }

When the two C<qr//> variables are interpolated like this a new
regex is compiled at runtime.  The lexicals are still bound to
C<$f> and C<$b>, and B<not> to this new regex that combines them.

And third, this won't do what you want either:

  while (<>) {
    for my $p (@lists) {
      next unless /(?<pat> $p)/; # WRONG
      print "Matched: $pat\n";
    }
  }

Here the regex is compiled at run-time because of the interpolated
C<$p> variable and by then it's too late to declare the lexicals.

In all these cases you should use the dynamically-scoped C<%{&}>
instead.

=head2 Functions

=over 4

=item install()

Install the modified regex engine.

=item uninstall()

Uninstall the modified regex engine.

=back

=head1 DIAGNOSTICS

=over 4

=item Sequence (?<name... not terminated

(F) You started a C<< (?<name> ...) >> pattern but forgot the C<< > >>.

=item Illegal character in (?<name> ...)

(F) Field names must start with a letter, and can contain only letters, 
numbers and underscores.

=item Field '%s' masks earlier declaration in same regex 

(W) You used the same field name twice in a single regex.  You can still
access the first field with C<$DIGIT>, but not with C<$&{name}>.

=item "%s" variable %s masks earlier declaration in same "%s"

(W) With the C<my> directive in effect, each field implicitly declares
a lexical variable.  See L<perldiag> for a full description of the warning.

=item Identifier too long

(F) You used a field name longer than Perl allows for a simple
identifier.  See L<perldiag>.

=item Sequence (?<%s...) not recognized

(F) You tried to compile a regex containing the C<< (?<name> ...) >>
extended pattern, but C<Regexp::Fields> wasn't installed at the time.
You can reinstall it at runtime with the L<install()> function.

=item corrupted regex program

(F) You compiled a regex with C<Regexp::Fields> installed, but tried 
to execute it with the standard regex engine.  You can reinstall it at
runtime with the L<install()> function.

=item Warning: Use of '%s' without parens is ambiguous

(W) Since '%' is the modulo operator as well as the hash sigil, the
parser suggests that C<keys %&> could mean keys-modulo-and rather than
keys-HASH.  Likewise with C<each()>.

You can hush the warning by adding parentheses (i.e. C<keys(%&)>) or
curly braces (C<keys %{&}>).  See L<perldiag> for a more complete
description of this warning.

=back

=head1 AUTHOR

Steve Grazzini (grazz@pobox.com)

=head1 THANKS

Thanks to Andrew Sterling Hanenkamp.

=head1 BUGS

Mail them to the author.

Known deficiencies include:

=over 4

=item 

The 'my' pragma doesn't work in 5.6.1.

=item 

You need to reinstall the modified regex engine every time you create
a new thread.

=item

There's a scoping problem when /g is used with /m or /s.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003, Steve Grazzini.  All rights reserved.

This module is free software; you can copy, modify and/or redistribute
it under the same terms as Perl itself.

