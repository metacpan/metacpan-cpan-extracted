use strict;
use warnings;

package Petal::CodePerl;

our $VERSION = '0.06';

use Petal;
use Petal::CodePerl::Modifiers;

$Petal::CodeGenerator = 'Petal::CodePerl::CodeGenerator';

use Petal::CodePerl::Modifiers;

use Scalar::Util;

our $InlineMod = 1;

# we will need to access these routines from insides Petal's Safe
# compartment

*Petal::CPT::Petal::XML_Encode_Decode::encode = \&Petal::XML_Encode_Decode::encode;
*Petal::CPT::Scalar::Util::blessed = \&Scalar::Util::blessed;
*Petal::CPT::Scalar::Util::reftype = \&Scalar::Util::reftype;
*Petal::CPT::UNIVERSAL::can = \&UNIVERSAL::can;

1;

__END__

=head1 NAME

Petal::CodePerl - Make Petal go faster by compiling the expressions

=head1 SYNOPSIS

  use Petal::CodePerl;

  # continue as you would normally using Petal

or

  use Petal;
  $Petal::CodeGenerator = 'Petal::CodePerl::CodeGenerator';
  
  # continue as you would normally use Petal

=head1 DESCRIPTION

This module provides a CodeGenerator for L<Petal> that inherits almost
everything from L<Petal::CodeGenerator> but modifies how expressions are
dealt with. Petal normally includes code like this

  $hash->get( "not:user" )

in the compiled template. This means the path has to be parsed and
interpreted at runtime. Using Petal::CodePerl, Petal will now produce this

  ! ($hash->{"user"})

which will be much faster.

It uses L<Parse::RecDescent> to parse the PETALES expressions which makes it
a bit slow to load the module but this won't matter much unless you have
turned off caching. It won't matter at all for something like Apache's
mod_perl.

=head1 USAGE

You have two choices, you can replace C<use Petal> with C<use
Petal::CodePerl> in all your scripts or you can do C<$Petal::CodeGenerator =
'Petal::CodePerl::CodeGenerator'>. Either of these will cause Petal to use
the expression compiling version of the CodeGenerator.

=head1 EXTRA BONUSES

Using L<Parse::RecDescent> makes it easier to expand the PETALES grammar. I
have made the following enhancements.

=over 2

=item *

alternators work as in TAL, so you can do

  petal:content="a/name|b/name|string:no name"

=item *

you can explicitly ask for hash, array or method in a path

=over 2

=item *

user{name} is $hash->{"user"}->{"name"}

=item *

user[1] is $hash->{"user"}->[1]

=item *

user/method() is $hash->{"user"}->method()

using these will make your template even faster although you need to be
certain of your data types.

=back

=item *

method arguments can be any expression for example

  user/purchase cookie{basket}
  
will give

  $hash->{"user"}->purchase($hash->{"cookie"}->{"basket"})

=item *

you can do more complex defines, like the following

  petal:define="a{b}[1] string:hello"

which will give

  $hash->{"a"}->[1] = "hello"

=item *

some other stuff that I can't remember just now.

=back

=head1 MODIFIERS

Modifiers can now be compiled, partially compiled or work exactly as they
did before. When compiling the expression, Petal::CodePerl will look at the
modifier's package to figure what it supports. The order of preference is
fully compiled, partially compiled, original style. So you can slowly
migrate you modifiers to full compilation.

Note that although original style still works, you cannot use any of the
extra features of Petal::CodePerl in the path if you are using an original
modifier. So you cannot do mymod:hash{key} until you convert your modifier
into one of the newer styles. This is because your original style modifier
uses L<Petal>'s parser and L<Petal>'s parser doesn't accept the {} syntax.
It would probably be possible to fix this too but I don't think it's worth
it. If you really need it, let me know.

=head2 Partially Compiled

Partially compiled modifiers are easiest, in fact they are even easier than
L<Petal>'s original style. To partially compile a modifier, define a package
with a C<process_value()> method, and put that into
C<%Petal::Hash::MODIFIERS> just as you would with a normal modifier package.

A simple example

  package Petal::Hash::Length;
  $Petal::Hash::MODIFIERS{"length:"} = "Petal::Hash::Length";

  sub process_value
  {
    my $class = shift;
    my $hash = shift;
    my $value = shift;

   return length($value);
  }

This is a little different to the C<process()> method originally used for
modifiers. For a path like true:this/is/a/path, Petal would call C<process()>
with 2 arguments - the Petal hash and the string "this/is/a/path", it was
then up to the method to parse that string and find the value that it
pointed to. For C<process_value()>, this string has already been parsed and
compiled, so the value defined by the path is passed in and can be used
straight away.

=head2 Fully Compiled

The most efficient but a little more complicated is fully compiled. For a
fully compiled modifier you need to have an C<inline()> method which will
return a L<Code::Perl> object that will produce the compiled code. It's not
a hard as it sounds. There is an easy to use L<Code::Perl> object provided
that makes this fairly straight-forward. Here's the example above rewritten as a fully
compiled modifier.

  package Petal::Hash::Length;
  $Petal::Hash::MODIFIERS{"length:"} = "Petal::Hash::Length";

  use Petal::CodePerl::Expr qw( perlsprintf );

  sub inline
  {
    my $class = shift;
    my $hash_obj = shift;
    my $value_obj = shift;

    return perlsprintf("length(%s)", $value_obj);
  }

The key points to note are that instead of getting the Petal hash and the
value of the expression you are modifying, you get L<Code::Perl> objects
representing them, you then use these objects to construct another
L<Code::Perl> object which will eventually spit out the Perl code for your
modifier. It's not in the example above but if your modifier wants to access
the Petal hash please don't write '$hash->{blah}', instead write
'%s->{blah}' and pass in the $hash_obj object. This allows for the
possibility in the future that the hash is not called '$hash'.

Why not just use simple strings? Because using L<Code::Perl> objects
instead of strings of Perl everywhere means you don't have to worry about
escaping and wrapping things in ()s and it means that modifiers can be
inside modifiers, deep inside complicated Petales expressions, which
themselves are inside a modifier etc, etc.

=head2 Tips for writing modifiers

The easiest way to write a compiled modifier is to write a partially
compiled one first and when you have that working perfectly, you can turn it
into a fully compiled one. If at any stage you need to go back to using the
partially compiled one, rather than commenting out the C<inline()> method
you can set C<$Petal::CodePerl::InlineMod = 0> and no C<inline()> methods
routines will be used.

If you are going to use the C<$value_obj> more than once in a compiled
modifier then you need to be a little bit careful as you only want to
calculate the value once. Say you have a modifier that takes a string and
doubles it, you could do this

  perlsprintf("%s.%s", $value_obj, $value_obj);

but then double:thing/method() would be compiled to

  ($hash->{thing}->method()).($hash->{thing}->method())

which is bad news because it's inefficient to call the method twice and
there's no guarantee that the method will actually return the same value for
each call. So what you should really do is

  perlsprintf("do{my $v = %s; $v.$v}", $value_obj);

giving

  do{my $v = ($hash->{thing}->method()); $v.$v}

which is efficient and safe.

=head2 Original

Any modifiers that are defined in the original Petal style, using a
C<process()> method will not be compiled and so will still work as before.

=head1 STATUS

Petal::CodePerl is in development. There are no known bugs and Petal passes
it's full test suite using this code generator. However there are probably
some differences between it's grammar and Petal's current grammar. Please
let me know if you find anything that works differently with
Petal::CodePerl.

=head1 PROBLEMS

Your templates may now generate "undefined value" warnings if you try to use
an undefined value. Previously, Petal prevented many of these from
occurring. As always, the best thing to do is not to avoid using undefined
values in your templates. Hopefully this will be fixed shortly.

=head1 AUTHOR

Written by Fergal Daly <fergal@esatclear.ie>.

=head1 COPYRIGHT

Copyright 2003 by Fergal Daly E<lt>fergal@esatclear.ieE<gt>.

This program is free software and comes with no warranty. It is distributed
under the LGPL license

See the file F<LGPL> included in this distribution or
F<http://www.fsf.org/licenses/licenses.html>.

=cut
