##################################################################
# Set::String
#
# See POD
##################################################################
package Set::String;
use strict;
use Carp qw/croak cluck/;
use Want;
use Set::Array;
use attributes qw(reftype);

use subs qw(chop chomp crypt defined eval index lc lcfirst ord);
use subs qw(pack pos substr uc ucfirst unpack);

# Subclass of Set::Array
BEGIN{
   use vars qw(@ISA $VERSION);
   @ISA = qw(Set::Array);
   $VERSION = '0.03';
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Used to decrypt an encrypted string.  Given that there's no
# way to access this variably directly (that I know of), I think
# this is a fairly safe implementation.
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my $decrypted;

sub new{
   my($class,$string) = @_;
   $string = @$class if !$string && ref($class);
   my @array = CORE::split('',$string);
   undef $string;
   return bless \@array, ref($class) || $class;
}

sub chop{
   my($self,$num) = @_;

   $num ||= 1;

   if(want('OBJECT') or !(CORE::defined wantarray)){
      for(1..$num){ $self->SUPER::pop }
      return $self;
   }

   my $copy = CORE::join('',@$self);
   my @chopped;
   for(1..$num){
      push(@chopped,CORE::chop $copy);
   }

   return reverse @chopped if wantarray;
   return scalar @chopped if defined wantarray;
}

sub chomp{
   my($self,$num) = @_;

   $num ||= 1;

   if(want('OBJECT') or !(CORE::defined wantarray)){
      my $string = join '',@$self;
      for(1..$num){
         CORE::chomp $string;
      }
      @$self = split '',$string;
      undef $string;
      return $self;
   }

   my $copy = CORE::join('',@$self);
   my @chomped;
   for(1..$num){
      push(@chomped,CORE::chop $copy);
   }

   return reverse @chomped if wantarray;
   return scalar @chomped if defined wantarray;
}

sub crypt{
   my($self,$salt) = @_;

   croak("No salt provided to 'crypt()' method") unless $salt;

   $decrypted = CORE::join('',@$self);
   my $temp = CORE::crypt($decrypted,$salt);

   if(want('OBJECT') or !(defined wantarray)){
      @$self = split('',$temp);
      undef $temp;
      return $self;
   }

   return $temp;
}

sub decrypt{
   my($self) = @_;

   unless(defined $decrypted){
      cluck("Pointless to decrypt an unencrypted string.  Ignoring");
      if(want('OBJECT') or !(defined wantarray)){ return $self }
      return @$self if wantarray;
      return join('',@$self) if defined wantarray;
   }

   if(want('OBJECT') or !(defined wantarray)){
      @$self = split('',$decrypted);
      return $self;
   }

   return $decrypted;
}

# Returns 1 or 0
sub defined{
   my($self) = @_;
   return 0 unless CORE::defined($self->[0]);
   return 1;
}

############################################################################
# Eval the string as is.  The object becomes the eval'd string, replacing
# the original content (or assigning them to an lvalue).
#
# I'm considering allowing an alternate string to be eval'd, but how do I
# handle it exactly?
############################################################################
sub eval{
   my($self) = @_;
   my $result = CORE::eval CORE::join('',@$self);
   if(want('OBJECT') or !(CORE::defined wantarray)){
      @$self = CORE::split('',$result);
      undef $result;
      return $self;
   }
   return $result;
}

sub index{
   my($self,$substr,$start) = @_;

   croak("No substring provided to 'index()' method") unless $substr;

   my $pos;
   if(defined $start){
      $pos = CORE::index(CORE::join('',@$self),$substr,$start);
   }
   else{
      $pos = CORE::index(CORE::join('',@$self),$substr);
   }

   if(want('OBJECT') or !(defined wantarray)){
      return bless \$pos;
   }

   return $pos if $pos;
   return -1;
}

###############################################################
# Slightly different from standard lc in that you can specify
# the number of characters you want to lc (left to right).
###############################################################
sub lc{
  my($self,$n) = @_;

  if( (CORE::defined $n) && ($n > scalar(@$self)) ){
     croak("Argument to method 'lc()' exceeds length of string");
  }

  $n ||= scalar(@$self);
  $n -= 1;
  if($n < 0){ $n = 0 }

  if($n !~ /\d+/){
     croak("Invalid argument to 'lc()' method");
  }

  if(want('OBJECT') || !(CORE::defined wantarray)){
     for(my $m = 0; $m <= $n; $m++){
        $self->[$m] = CORE::lc($self->[$m]);
     }
     undef $n;
     return $self;
  }

  my $copy = CORE::join('',@$self);
  return CORE::lc($copy);
}

sub lcfirst{
   my($self) = @_;

   if(want('OBJECT') || !(CORE::defined wantarray)){
      $self->[0] = CORE::lc($self->[0]);
      return $self;
   }

  my $copy = CORE::join('',@$self);
  return CORE::lcfirst($copy);
}

###############################################################################
# Slightly different than standard 'ord' in that the programmer may
# specify a range of characters to get ord vals on.  Alternatively, a single
# index may be specified.
#
# By default, this method will return all ord values unless an
# index is specified.  Returns a list or list ref.
###############################################################################
sub ord{
   my($self,$num) = @_;

   cluck("Calling 'ord()' on empty array") if scalar(@$self) == 0;

   $num = scalar(@$self) unless CORE::defined $num;

   $num--;

   if(want('OBJECT') or !(defined wantarray)){
      for(0..$num){ $self->[$_] = CORE::ord($self->[$_]) }
      return $self;
   }

   my @copy = @$self;
   for(0..$num){ $copy[$_] = CORE::ord($copy[$_]) }

   return @copy if wantarray;
   return \@copy if defined wantarray;
}

# Overload the Set::Array version of pack (and unpack)
sub pack{
   my($self,$template) = @_;

   croak("No template provided to 'pack()' method") unless $template;

   if(want('OBJECT') || !(defined wantarray)){
      @$self = join('',@$self);
      @$self = CORE::pack($template,@$self);
      return $self;
   }

   my @temp = join('',@$self);
   return CORE::pack($template,@temp);
}

###########################################################################
# Returns an index or array of indices
#
# e.g. if string is "fee fie foe foo" and 'e' is the pattern, 2,3,7 and 11
# would be returned.
###########################################################################
sub pos{
   my($self,$pattern) = @_;

   croak("No pattern supplied to 'pos()' method") unless $pattern;

   my @indices;
   my $string = CORE::join('',@$self);

   while($string =~ /$pattern/g){
      my $pos = CORE::pos $string;
      push @indices, $pos;
   }
  
   if(want('OBJECT') or !(defined wantarray)){
      @$self = @indices;
      undef @indices;
      return $self;
   }

   return @indices if wantarray;
   return \@indices if defined wantarray;
}

sub substr{
   my($self,$offset,$length) = @_;
   
   croak("No offset specified for 'substr()' method") unless defined $offset;

   if( (defined $length) && ($length <= 0) ){
      croak("Nonsensical value used as length for 'substr()' method");
   }

   my $string = CORE::join('',@$self);

   my $substr;

   if($length){
      $substr = CORE::substr($string,$offset,$length);
   }
   else{
      $substr = CORE::substr($string,$offset);
   }

   if( want('OBJECT') or !(defined wantarray) ){
      @$self = CORE::split('',$substr);
      undef $string;
      return $self;
   }

   return $substr;
}

# Not yet implemented
sub unpack{
   my($self,$template) = @_;
   
   croak("No template provided to 'unpack()' method") unless $template;

   if( want('OBJECT') or !(defined wantarray) ){
      @$self = CORE::unpack($template,join('',@$self));
      return $self;
   }

   my $temp = join('',@$self);
   if(wantarray){ return CORE::unpack($template,$temp) }
   if(defined wantarray){ return CORE::unpack($template,$temp) }
}

# Not yet implemented
#sub quotemeta{}

# Not yet implemented
#sub split{}

# May not be implemented
#sub study{}

###############################################################
# Slightly different from standard uc in that you can specify
# the number of characters you want to uc (left to right).
###############################################################
sub uc{
  my($self,$n) = @_;

  if( (CORE::defined $n) && ($n > scalar(@$self)) ){
     croak("Argument to method 'uc()' exceeds length of string");
  }

  $n ||= scalar(@$self);
  $n -= 1;
  if($n < 0){ $n = 0 }

  if($n !~ /\d+/){
     croak("Invalid argument to 'uc()' method");
  }

  if(want('OBJECT') || !(CORE::defined wantarray)){
     for(my $m = 0; $m <= $n; $m++){
        $self->[$m] = CORE::uc($self->[$m]);
     }
     undef $n;
     return $self;
  }

  my $copy = CORE::join('',@$self);
  return CORE::uc($copy);
}

sub ucfirst{
   my($self) = @_;

   if(want('OBJECT') || !(CORE::defined wantarray)){
      $self->[0] = CORE::uc($self->[0]);
      return $self;
   }

  my $copy = CORE::join('',@$self);
  return CORE::ucfirst($copy);
}

# Not yet implemented
#sub vec {}
1;
__END__

=head1 NAME

Set::String - Strings as objects with lots of handy methods (including set
comparisons) and support for method chaining.

=head1 SYNOPSIS

C<< my $s1 = Set::String->new("Hello"); >>

C<< my $s2 = Set::String->new("World!\n"); >>

C<< $s1->length->print; # prints 5 >>

C<< $s1->ord->join->print; # prints 72,101,108,108,111 >>

C<< $s2->chop(3)->print; # prints 'Worl' >>


=head1 PREREQUISITES

Perl 5.6 or later

Set::Array (also by me).  Available on CPAN.

The 'Want' module by Robin Houston.  Available on CPAN.

=head1 DESCRIPTION

Set::String allows you to create strings as objects and use OO-style methods
on them.  Many convenient methods are provided here that appear in the
FAQ's,
the Perl Cookbook or posts from comp.lang.perl.misc.
In addition, there are Set methods with corresponding (overloaded)
operators for the purpose of Set comparison, i.e. B<+>, B<==>, etc.

The purpose is to provide built-in methods for operations that people are
always asking how to do, and which already exist in languages like Ruby.
This
should (hopefully) improve code readability and/or maintainability.  The
other advantage to this module is method-chaining by which any number of
methods may be called on a single object in a single statement.

Note that Set::String is a subclass of Set::Array, and your string objects
are really just treated as an array of characters, ala C.  All methods
available
in Set::Array are available to you.

=head1 OBJECT BEHAVIOR

The exact behavior of the methods depends largely on the calling context.

B<Here are the rules>:

* If a method is called in void context, the object itself is modified.

* If the method called is not the last method in a chain (i.e. it's called
  in object context), the object itself is modified by that method
regardless
  of the 'final' context or method call.

* If a method is called in list or scalar context, a list or list
refererence
  is returned, respectively. The object itself is B<NOT> modified.

Here is a quick example:

C<< my $so = Set::String->new("Hello"); >>

C<< my @uniq = $so->unique(); # Object unmodified. >>

C<< $so->unique(); # Object modified, now contains 'Helo' >>

B<Here are the exceptions>:

* Methods that report a value, such as boolean methods like I<defined()>,
  never modify the object.

=head1 BOOLEAN METHODS

B<defined()> - Returns 1 if the string is defined.  Otherwise a 0 is
returned.

=head1 STANDARD METHODS

B<chomp(>I<?int?>B<)> - Deletes the last character of the string that
corresponds to $/, or the newline by default.  Optionally you may pass an
integer to this method to indicate the number of times you want the string
chomped.  In list context, a list of chomped values is returned.  In scalar
context, the number of chomped values is returned.

B<chop(>I<?int?>B<)> - Deletes the last character of the string.  Optionally
you may pass an integer to this method to indicate the number of times you
want the string chopped.  In list context, a list of chopped values is
returned.  In scalar context, the number of chopped values is returned.

B<crypt(>I<salt>B<)> - Encrypts the string, converting it into a 13-character
string, with the first two characters as the I<salt>.  Unlike Perl's builtin
I<crypt> function, you B<CAN> decrypt the object to get the original string
using the I<decrypt()> method.

B<decrypt> - Decrypts an encrypted string.  Attempting to decrypt an
unencrypted string will generate a warning.  Returns the decrypted string
in either list or scalar context.

B<eval> - Evaluates the string and returns the result.

B<index(>I<substring>B<)> - Returns the position of the first occurrence
of I<substring> within the string.  If the index is not found, a -1 is
returned instead.

B<lc(>I<?int?>B<)> - Lower case the string.  Optionally, you may pass an
integer
value to this method, in which case only that number of characters will be
lower cased (left to right), instead of the entire string.

B<lcfirst> - Lower case the first character of the string.

B<ord(>I<?int?>B<)> - Converts the string to a list of ord values, one per
character.  Alternatively, you may provide an optional integer argument, in
which case only that number of characters will be converted to ord values.
An array or array ref of ord values is returned in list or scalar context,
respectively.

B<pack(>I<template>B<)> - Packs the string according to the template provided

B<pos(>I<pattern>B<)> - Returns the location in your string where the last
global search left off.  If more than one location is found, it will return
an array of integers (or an array ref in scalar context).

B<substr(>I<offset>,I<?length?>B<)> - Returns a substring of the object
string, starting at I<offset> (with 0 as the first char) and continuing
until I<length>, or the end of the string if the length is not specified.
If the offset is negative, then it will start at the end of the string.

Returns the substring in either list or scalar context.

B<uc(>I<?int?>B<)> - Upper case the string.  Otherwise identical to the
'lc()' method, above.

B<unpack(>I<template>B<)> - Unpacks the string according to the template.  Probably
best used when *not* part of a chain, as your result will always be concatenated
into one big string otherwise.

=head1 FAQ

I<How can you decrypt an encrypted string?  How are you doing this?>

When the I<crypt()> method is called, a copy of the original string is
placed in a lexical variable within the package.  Since there's no
way to access that variable *except* through the object (as far as I
know), your string is secure.

Note that I wouldn't rely on I<crypt()> to provide true encryption.
For that, you ought to be using one of the more modern cryptographic
modules.

=head1 KNOWN BUGS

None.  Please let me know if you find any.

=head1 FUTURE PLANS

Add the 'vec' method

Allow arguments to be passed to the 'eval()' method.  I am not sure what the
behavior should be at that point, however.  Should it replace the string
object? Should the results of that evaluation be appended to the original
string? Ideas welcome.

Add character ranges to some of the methods

How about a boolean method 'palindrome'?  Perhaps a subclass of Set::String,
called Set::String::Grammar.  It could have a series of boolean methods like
'verb()', 'adjective()', etc.

=head1 AUTHOR

Daniel Berger

djberg96@hotmail.com
