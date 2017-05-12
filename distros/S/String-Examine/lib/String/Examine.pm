package String::Examine;

=head1 NAME

String::Examine - String comparisions and offset checking

=head1 SYNOPSIS
   
   use String::Examine;

   my $str = String::Examine::new('string1' => 'foo', $string2 => 'bar');
   my $match = $str->compare();
   my $match2 = $str->nocase_compare();
   my $match3 = $str->regex_compare();
   my $match4 = $str->vector_compare();

   if($match || $match2 || $match3 || $match4)
   {
      my $offset = $str->str_pos();
   }

   $str->string2("new_string");
   $str->string1("new_string_also");

=head1 DESCRIPTION

This module does basic string comparision, string1 is always the primary that string2 is matched against
there is 4 builtin comparisions, 'compare()' which just does a basic eq/ne compare, 'nocase_compare()' 
which converts to lowercase and does eq/ne match, 'regex_compare()' which is simply string matching using m//,
'vector_compare()' a slightly more unusual comparision, converts each character into vector and concatenates 
the converted vectors and does a '==' there is instances on some strings where this has found a failure that 
other compares failed to find, however, due to the nature it is the most expensive compare.

The final function is 'str_pos()' in the event that a string doesn't match this function can be called to find 
the position in the string2 where it failed, it is offset from 0, ie:

string1 = 'aaaaba';
string2 = 'aaaaaa';

str_pos() would return '4'.

=cut

use 5.008007;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw/new string1 string2 compare nocase_compare regex_compare vector_compare str_pos/;
@EXPORT = qw//;
%EXPORT_TAGS = (all => [@EXPORT_OK]);
$VERSION = '0.01';


=head1 FUNCTIONS

=head2 new

my $str = String::Examine::new();

You can pass the optional parameters 'string1', and 'string2' here.

=cut

sub new
{
   my $class           = "String::Examine";
   my %params          = @_;
   my $self            = {};
   $self->{'_string1'} = $params{'string1'} || undef;
   $self->{'_string2'} = $params{'string2'} || undef;
   bless $self, $class;
   return $self;
}

=head2 string1

$str->string1("string");

If a value is pass string1 will be set to the value if not it will just return the 
currently set value.

=cut

sub string1
{
   my ($self, $new_val) = @_;
   $self->{'_string1'} = $new_val if $new_val;
   return $self->{'_string1'};
}

=head2 string2

$str->string2("string");

If a value is pass string2 will be set to the value if not it will just return the 
currently set value.

=cut

sub string2
{
   my ($self, $new_val) = @_;
   $self->{'_string2'} = $new_val if $new_val;
   return $self->{'_string2'};
}

=head2 compare

$str->compare();

Performs a basic eq compare on string1 and string2, string1 is always primary, 
returns 0 strings are equal or 1 if not

=cut

sub compare
{
   my $self = shift;
   
   if($self->{'_string1'} eq $self->{'_string2'})
   {
      return 0;
   }
   else
   {
      return 1;
   }
}

=head2 nocase_compare

$str->nocase_compare();

Exactly as compare() except it performs lc() first.

=cut

sub nocase_compare
{
   my $self = shift;

   if(lc($self->{'_string1'}) eq lc($self->{'_string2'}))
   {
      return 0;
   }
   else
   {
      return 1;
   }
}

=head2 regex_compare

$str->regex_compare();

Performs the compare based on a regular expression using string1 =~ m/string2/
returns 0 if they are equal or 1 if not.

=cut

sub regex_compare
{
   my $self = shift;

   if($self->{'_string1'} =~ m/$self->{'_string2'}/)
   {
      return 0;
   }
   else
   {
      return 1;
   }
}

=head2 vector_compare

$str->vector_compare();

Converts the strings into 4bit vectors and performs a compare based on the concatenated output.

=cut

sub vector_compare
{
   my $self = shift;
   my ($vec1, $vec2);

   foreach my $c (split //, $self->{'_string1'})
   {
      $vec1 .= vec($c, 0, 4);
   }
   
   foreach my $c (split //, $self->{'_string2'})
   {
      $vec2 .= vec($c, 0, 4);
   }

   if($vec1 == $vec2)
   {
      return 0;
   }
   else
   {
      return 1;
   }
}

=head2 str_pos

$str->str_pos();

Returns the offset number of string2 at the point at which the 2 strings do not match, counts from 0.

=cut

sub str_pos
{
   my $self = shift;
   my $strcount = 0;
   my @str1 = split(//, $self->{'_string1'});
   my @str2 = split(//, $self->{'_string2'});

   foreach my $char (@str1)
   {
      if($char ne $str2[$strcount])
      {
	 return $strcount;
      }
      $strcount++;
   }

   return -1;   
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head2 EXPORT

None by default.

=head1 AUTHOR

Ben Maynard, E<lt>cpan@geekserv.com<gt> E<lt>http://www.webcentric-hosting.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ben Maynard, E<lt>cpan@geekserv.com<gt> E<lt>http://www.webcentric-hosting.com<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
