package Net::DSML::Filter;

use warnings;
use strict;
#use Carp;
use Class::Std::Utils;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use version; $VERSION = version->new('0.002');

# Copyright (c) 2007 Clif Harden <charden@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

{

BEGIN
{
  use Exporter ();

  @ISA = qw(Exporter);
  @EXPORT = qw();
  %EXPORT_TAGS = ();
  @EXPORT_OK  = ();

}


# 
# The class filter provides methods for building ldap dsml search filters.
# 
my %sfilter;
my %debug;
my %errMsg;
my %msg;

#
#  initialize the new object.
#  
# Method new
# 
# The new method initializes a new filter object.
# 
# This method has 1 valid option; debug; value of 1 or 0.  This will enable
# debug messages to standard out.
# 

sub new
{
  my ($class, $opt) = @_;
  my $self = bless anon_scalar(), $class;

  $sfilter{ident $self} = ""; # Search filter
  $debug{ident $self} = $opt->{debug} ? 1 : 0; # debug flag
  $errMsg{ident $self} = ""; #  error messages, no error this will be a null string.
  $msg{ident $self} = ""; # general messages
  return $self;
}

#
# inside-out classes have to have a DESTROY subrountine.
#
sub DESTROY
{
  my ($dsml) = @_;
  my $id = ident($dsml);

  delete $sfilter{$id};
  delete $debug{$id};
  delete $errMsg{$id};
  delete $msg{$id};
  return;
}

# Method debug
#
# The method debug sets or returns the object debug flag.
#
# If there is one required input option.
#
# $return = $dsml->debug( 1 );
#
# Input option:  Debug value; 1 or 0.  Default is 0.
#
# Method output; Returns debug value.
#

sub debug
{
  my $dsml = shift;
  $debug{ident $dsml} = shift if ( @_ >= 1 );
  return $debug{ident $dsml};
}


#  Method error
# 
# The error method returns error message that is stored in the 
# object.  Any error message will be associated with the last
# filter module operation.
# 
# No input options.
# 
# Example:  $filter->error;
# 

sub error
{
  my ($dsml) = @_;
  return $errMsg{ident $dsml};
}


#  Method getFilter
#
# The getFilter method returns the last filter string that was 
# created.
# 
# No input options.
# 
# Example:  $filter->getFilter;
# 

sub getFilter
{
  my ($dsml) = @_;
  my $id;
  $id = ident $dsml;

  if ( !($sfilter{$id} =~ /<filter>/) )
  {
     $sfilter{$id} = "<filter>" . $sfilter{$id} . "</filter>";
  }
  return $sfilter{$id};
}


#   1.  & - &amp;
#   2. < - &lt;
#   3. > - &gt;
#   4. " - &quot;
#   5. ' - &#39; 
#
#   Convert special characters to xml standards.
#
sub _specialChar
{
  my ($char) = @_;

  $$char =~ s/&/&amp;/g;
  $$char =~ s/</&lt;/g;
  $$char =~ s/>/&gt;/g;
  $$char =~ s/"/&quot;/g;
  $$char =~ s/'/&#39;/g;

}

#  Method setFilter
# 
# The setFilter method sets the objects filter string.  This 
# could be used as a base to continue building the filter string.
# 
# Example:  $filter->setFilter($value);
# 
# There is 1 input option ($value):  filter string.
# 

sub setFilter
{
  my ($dsml, $value) = @_;
  my $refvalue;
  $refvalue = (ref($value) ? ${$value} : $value);
  if ( length($refvalue) > 0 )
  {
     _specialChar(\$refvalue) if ( $refvalue =~ /(&||<||>||"||')/);
     $sfilter{ident $dsml} = $refvalue;
     return 1;
  }
   
  $errMsg{ident $dsml} = "Method setFilter filter value is not defined.";
  return 0;

}


#  Method reset
# 
# The reset method will reset the filter string to a null, or blank,
# value.  
# 
# No input options.
# 
# Example:  $filter->reset;
# 

sub reset
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} = "";
  return 1;
}

# Method subString
# 
# The method subString sets up a LDAP substring filter.
# 
# There are 3 required input options.
# 
# $return = $filter->subString( type => "initial, 
#                               attribute => "cn", 
#                               value => "Bugs Bunny" );
# 
# Input option "type":  String that contains the type of substring 
# search that is being preformed; final, any, initial.
# 
# Input option "attribute": String that contains the attribute name 
# that controls the search.
# 
# Input option  "value": String that contains the value of the 
# attribute.
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub subString
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $attribute;
  my $value;
  my $type;
  $errMsg{$id} = "";

  $attribute = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});
  $type = (ref($opt->{type}) ? ${$opt->{type}} : $opt->{type});

  if ( defined($opt->{attribute}) && 
       defined($opt->{value}) && 
       defined($opt->{type}) )
  {
      _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
      $_ = lc($type); 
      if ( /^(final||initial||any)$/ ) 
      {
          $sfilter{$id} .= "<substrings name=\"" . $attribute . "\"><" . $1 . ">" . $value . "</" . $1 . "></substrings>";
          return 1;
      }

      $errMsg{$id} = "Requested substring type does not match final, any or initial.";
      return 0;

  }
  else
  {
  #
  #  Substring error conditions
  #
      if ( (@_) < 6 )
      {
          $errMsg{$id} = "Subroutine subString did not have enough parameters defined.";
      }
      elsif ( !defined($opt->{attribute}) )
      {
          $errMsg{$id} = "Subroutine subString attribute string is not defined.";
      }
      elsif ( !defined($opt->{value}) )
      {
          $errMsg{$id} = "Subroutine subString value string is not defined.";
      }
      elsif ( !defined($opt->{type}) )
      {
          $errMsg{$id} = "Subroutine subString type string is not defined.";
      }
      return 0;
  }

}


# Method present
# 
# The method present sets up a LDAP present filter.
# 
# There is 1 required input option.
# 
# $return = $filter->present(  { attribute => "cn" } );
# 
# Input option "attribute": String that contains the attribute name 
# that controls the search.
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub present
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $refvalue;

  $errMsg{$id} = "";
  $refvalue = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  if ( !defined($opt->{attribute}) )
  {
     $errMsg{$id} = "Subroutine present attribute string is not defined.";
     return 0;
  }
  $sfilter{$id} .= "<present name=\"" . $refvalue . "\"/>";
  return 1;
}


# Method equalityMatch
# 
# The method equalityMatch sets up a LDAP equality match filter.
# 
# There are 2 required input options.
# 
# $return = $filter->equalityMatch( { attribute => "sn", value => "Bunny"  } );
# 
# Input option "attribute": String that contains the attribute name 
# that controls the search.
# 
# Input option  "value": String that contains the attribute value.
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub equalityMatch
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $attribute;
  my $value;
  $errMsg{$id} = "";
  $attribute = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});

  if ( defined($opt->{attribute}) && defined($opt->{value}) )
  {
      _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
      $sfilter{$id} .= "<equalityMatch name=\"" . $attribute . "\"><value>" . $value . "</value></equalityMatch>";

      #print $sfilter{$id}, "\n"; # if ( $debug{$id} );
      return 1;
  }
  else
  {

    if ( (@_) < 2 )
    {
        $errMsg{$id} = "Subroutine equalityMatch did not have enough parameters defined.";
    }
    elsif ( !defined($opt->{attribute}) )
    {
       $errMsg{$id} = "Subroutine equalityMatch attribute string is not defined.";
    }
    elsif ( !defined($opt->{value}) )
    {
       $errMsg{$id} = "Subroutine equalityMatch value string is not defined.";
    }
    return 0;
  }
}


# Method greaterOrEqual
# 
# The method greaterOrEqual sets up a LDAP greater or equal filter.
# 
# There are 2 required input options.
# 
# $return = $filter->greaterOrEqual( { attribute => "uid", value => "bugs" } );
# 
# Input option "attribute": String that contains the attribute name 
# that controls the search.
# 
# Input option  "value": String that contains the value of the 
# attribute.
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub greaterOrEqual
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $attribute;
  my $value;

  $errMsg{$id} = "";
  $attribute = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});

  if ( defined($opt->{attribute}) && defined($opt->{value}) )
  {
      _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
      $sfilter{$id} .= "<greaterOrEqual name=\"" . $attribute . "\"><value>" . $value . "</value></greaterOrEqual>";
      return 1;
  }
  else
  {
    if ( (@_) < 4 )
    {
        $errMsg{$id} = "Subroutine greaterOrEqual did not have enough parameters defined.";
    }
    elsif ( !defined($opt->{attribute}) )
    {
        $errMsg{$id} = "Subroutine greaterOrEqual attribute string is not defined.";
    }
    elsif ( !defined($opt->{value}) )
    {
        $errMsg{$id} = "Subroutine greaterOrEqual value string is not defined.";
    }
    return 0;
  }
}



# Method lessOrEqual
# 
# The method lessOrEqual sets up a LDAP less or equal filter.
# 
# There are 2 required input options.
# 
# $return = $filter->lessOrEqual( { attribute => "uid", value => "turkey" } );
# 
# Input option "attribute": String that contains the attribute name 
# that controls the search.
# 
# Input option  "value": String that contains the value of the 
# attribute.
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub lessOrEqual
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $attribute;
  my $value;
  $errMsg{$id} = "";

  $attribute = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});

  if ( defined($opt->{attribute}) && defined($opt->{value}) )
  {
      _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
      $sfilter{$id} .= "<lessOrEqual name=\"" . $attribute . "\"><value>" . $value . "</value></lessOrEqual>";
      return 1;
  }
  else
  {
    if ( (@_) < 4 )
    {
        $errMsg{$id} = "Subroutine lessOrEqual did not have enough parameters defined.";
    }
    elsif ( !defined($opt->{attribute}) )
    {
        $errMsg{$id} = "Subroutine lessOrEqual attribute string is not defined.";
    }
    elsif ( !defined($opt->{value}) )
    {
        $errMsg{$id} = "Subroutine lessOrEqual value string is not defined.";
    }
    return 0;
  }
}


# Method approxMatch
# 
# The method approxMatch sets up a LDAP approximate match filter.
# 
# There are 2 required input options.
# 
# $return = $filter->approxMatch( { attribute => "uid", value => "bird" } );
# 
# Input option "attribute": String that contains the attribute name 
# that controls the search.
# 
# Input option  "value": String that contains the value of the 
# attribute.
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub approxMatch
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $attribute;
  my $value;
  $errMsg{$id} = "";

  $attribute = (ref($opt->{attribute}) ? ${$opt->{attribute}} : $opt->{attribute});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});

  if ( defined($opt->{attribute}) && defined($opt->{value}) )
  {
      _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
      $sfilter{$id} .= "<approxMatch name=\"" . $attribute . "\"><value>" . $value . "</value></approxMatch>";
      return 1;
  }
  else
  {
    if ( (@_) < 4 )
    {
        $errMsg{$id} = "Subroutine approxMatch did not have enough parameters defined.";
    }
    elsif ( !defined($opt->{attribute}) )
    {
        $errMsg{$id} = "Subroutine approxMatch attribute string is not defined.";
    }
    elsif ( !defined($opt->{value}) )
    {
        $errMsg{$id} = "Subroutine approxMatch value string is not defined.";
    }
    return 0;
  }
}


# Method extensibleMatch
# 
# The method extensibleMatch sets up a LDAP extensibleMatch filter.
# 
# There is 1 required input options.
# Input option  "value": String that contains the value of the 
# attribute.
# There are 3 optional options.
# Input option  "matchingRule": String that contains the value of the 
# matchingRule.
# Input option  "dnAttributes": String that contains the boolean value 
# of true or false
# Input option  "name": String that contains the name string.
# 
# 
# $return = $filter->extensibleMatch( { value =>" ",
#                                       name => " ",
#                                       matchingRule => " ",
#                                       dnAttributes => " " } );
# 
# Method output;  Returns true on success; false on error, error message 
# can be gotten with error property.
# 

sub extensibleMatch
{
  my ($dsml, $opt) = @_;
  my $id = ident($dsml);
  my $name;
  my $value;
  my $mrule;
  my $dnAttributes;
  $errMsg{$id} = "";

  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});
  $name = (ref($opt->{name}) ? ${$opt->{name}} : $opt->{name}) if ( $opt->{name});
  $mrule = (ref($opt->{matchingRule}) ? ${$opt->{matchingRule}} : $opt->{matchingRule}) if ( $opt->{matchingRule});
  $dnAttributes = (ref($opt->{dnAttributes}) ? ${$opt->{dnAttributes}} : $opt->{dnAttributes}) if ( defined($opt->{dnAttributes}) );

    if ( $opt )
    {
       if ( !$opt->{value} )
       {
           $errMsg{$id} = "Subroutine extensibleMatch value string is not defined.";
           return 0;
       }

       $_ = lc($dnAttributes) if ( defined($opt->{dnAttributes}) );

       if ( defined($_) && !(/^(true)||(false)$/) )
       {
          $errMsg{$id} = "Subroutine extensibleMatch dnAttributes string is not properly defined.";
          return 0;
       }

         _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);

        if ( $opt->{name})
        {
          _specialChar(\$name) if ( $name =~ /(&||<||>||"||')/);
        }

        if ( $opt->{matchingRule})
        {
          _specialChar(\$mrule) if ( $mrule =~ /(&||<||>||"||')/);
        }

         $sfilter{$id} .= "<extensibleMatch";
         $sfilter{$id} .= " name=\"" . $name . "\"" if ($name);
         $sfilter{$id} .= " dnAttributes=\"" . $dnAttributes . "\"" if ($opt->{dnAttributes});
         $sfilter{$id} .= " matchingRule=\"" . $mrule . "\"" if ($opt->{matchingRule});
         $sfilter{$id} .= "><value>" . $value . "</value></extensibleMatch>";
         return 1;
      }
      else
      {
        $errMsg{$id} = "Subroutine extensibleMatch had no input options defined.";
        return 0;
      }
}

# Method or
# 
# The method or sets up a beginning or element of a LDAP or filter.
# 
# There are no required input options.
# 
# $return = $filter->or();
# 
# Method output;  Always returns true for success.
# 

sub or
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} .= "<or>";
  return 1;
}

# Method endor
# 
# The method endor sets up a ending or element of a LDAP or filter.
# 
# There are no required input options.
# 
# $return = $filter->or();
# 
# Method output;  Always returns true for success.
# 

sub endor
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} .= "</or>";
  return 1;
}


# Method and
# 
# The method and sets up a beginning and element of a LDAP and filter.
# 
# There are no required input options.
# 
# $return = $filter->and();
# 
# Method output;  Always return true for success.
# 

sub and
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} .= "<and>";
  return 1;
}

# Method endand
# 
# The method endand sets up a ending and element of a LDAP and filter.
# 
# There are no required input options.
# 
# $return = $filter->endand();
# 
# Method output;  Always returns true for success.
# 

sub endand
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} .= "</and>";
  return 1;
}

# Method not
# 
# The method not sets up a beginning not element of a LDAP not filter.
# 
# There are no required input options.
# 
# $return = $filter->not();
# 
# Method output;  Always return true for success.
# 

sub not
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} .= "<not>";
  return 1;
}

# Method endnot
# 
# The method endnot sets up the ending not element of a LDAP not filter.
# 
# There are no required input options.
# 
# $return = $filter->endnot();
# 
# Method output;  Always returns true for success.
# 

sub endnot
{
  my ($dsml) = @_;
  $sfilter{ident $dsml} .= "</not>";
  return 1;
}

}


1; # Magic true value required at end of module

__END__

=head1 NAME

Net::DSML::filter.pm -  A perl module that supplies a Net::DSML::Filter object that is used by a Net::DSML object.


=head1 VERSION

This document describes Net::DSML::filter version 0.002


=head1 SYNOPSIS

filter.pm -  A perl module that supplies several different LDAP DSML 
filter types.

This module is used in conjunction with the Net::DSML module which 
does LDAP DSML queries to a LDAP directory server.

The DSML xml format is very strict and unforgiving of errors.
Because of this I have made the calling of these filter methods
strict also.  The methods expect variables to be in a 
certain order.

Also methods are expected to be called in a certain order 
also.

The following is an example of building a I<simple> subString filter.

=over 4

 # Create the filter object.
 my $webfilter = Net::DSML::filter->new(debug => 1);

 # put the subString xml elements on the filter string
 $webfilter->subString( { type => "initial", 
                          attribute => "uid", 
                          value => "Bugs" } );

 # Get the resulting filter
 $filter = $webfilter->getFilter();  

=back


The following is an example of building a I<compound> equalityMatch
filter.

=over 4

 # Create the filter object.
 my $webfilter = filter->new(debug => 1);

 # Put the <filter> element on the filter string
 $webfilter->start();  

 # Use the "and" to make compound filter
 $webfilter->and();
 
 # put the equalityMatch xml elements on the filter string
 $webfilter->equalityMatch({ attribute => "sn", 
                             value => "Bunny" } );

 # put the equalityMatch xml elements on the filter string
 $webfilter->equalityMatch( { attribute => "givenname", 
                               value => "jay" } );

 # Put the ending and </and> element on the filter string
 $webfilter->endand();

 # Put the </filter> element on the filter string
 $webfilter->terminate();

 # Get the resulting filter
 $filter = $webfilter->getFilter();  

=back

The following is an example of building a I<complex compound> equalityMatch
filter.

=over 4

 # Create the filter object.
 my $webfilter = Net::DSML::filter->new(debug => 1);

 # Put the <filter> element on the filter string
 $webfilter->start();  

 # Use the "and" to make compound filter
 $webfilter->and();

 # put the equalityMatch xml elements on the filter string
 $webfilter->equalityMatch( { attribute => "sn", 
                              value => "Bunny" } );

 # Use the "not" to make more complex compound filter
 $webfilter->not();

 # put the equalityMatch xml elements on the filter string
 $webfilter->equalityMatch( { attribute => "givenname", 
                              value => "jay" } );

 # Put the ending not </not> element on the filter string
 $webfilter->endnot();

 # Put the ending and </and> element on the filter string
 $webfilter->endand();

 # Put the </filter> element on the filter string
 $webfilter->terminate();

 # Get the resulting filter
 $filter = $webfilter->getFilter();  

=back

By combining the and, or , and not methods you can make some very
complex filters.
  
  
  
=head1 DESCRIPTION

The Net::DSML::filter module is used the build the DSML xml filter
string that is the by the Net::DSML module when building a complete
DSML xml string that will be send to a DSML http server that is usually
located on a LDAP directory server.

=head1 INTERFACE 

=over 4

=item B<new ( {OPTIONS} )>

The new method is the constructor for a new filter object.

Example:  $filter = Net::DSML::filter->new({ debug => 1 } );

This method has 1 valid option, debug; value of 1 or 0.  This will enable
debug messages to be printed to standard out.


=item B<debug ( {OPTIONS} )>

The method debug sets or returns the object debug flag.

If there is one required input option.

 Input option:  value 1 or 0.  Default is 0.

 $return = $dsml->debug( 1 );

Method output; Returns debug value.


=item B<error ()>

The error method returns error message that is stored in the 
object.  Any error message will be associated with the last
filter module operation.

No input options.

Example:  $filter->error();


=item B<getFilter ()>

The getFilter method returns the last filter string that was 
created.

No input options.

Example:  $filter->getFilter();


=item B<setFilter ( {OPTIONS} )>

The setFilter method sets the objects filter string.  This 
could be used as a base to continue building the filter string.

Example:  $filter->setFilter($value);

There is 1 input option ($value):  user created  filter string.


=item B<reset ()>

The reset method will reset the filter string to a null, or blank,
value.  

No input options.

Example:  $filter->reset();

=item B<subString ( {OPTIONS} ) >

The method subString sets up a DSML substring filter.

There are 3 required input options.

 Input option "type":  String that contains the type of substring 
 search that is being preformed; final, any, initial.
 Input option "attribute": String that contains the attribute name 
 that controls the search.
 Input option  "value": String that contains the value of the 
 attribute.

 $return = $filter->subString( type => "initial, 
                               attribute => "cn", 
                               value => "Bugs Bunny" );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.


=item B<present ( {OPTIONS} )>

The method present sets up a DSML present filter.

There is 1 required input option.

 Input option "attribute": String that contains the attribute name 
 that controls the search.

 $return = $filter->present(  { attribute => "cn" } );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.


=item B<equalityMatch ( {OPTIONS} )>

The method equalityMatch sets up a DSML equality match filter.

There are 2 required input options.

 Input option "attribute": String that contains the attribute name 
 that controls the search.
 Input option  "value": String that contains the attribute value.

 $return = $filter->equalityMatch( { attribute => "sn", 
                                     value => "Bunny"  } );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.


=item B<greaterOrEqual ( {OPTIONS} )>

The method greaterOrEqual sets up a DSML greater or equal filter.

There are 2 required input options.

 Input option "attribute": String that contains the attribute name 
 that controls the search.
 Input option  "value": String that contains the value of the 
 attribute.

 $return = $filter->greaterOrEqual( { attribute => "uid", 
                                      value => "bugs" } );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.


=item B<lessOrEqual ( {OPTIONS} )>

The method lessOrEqual sets up a DSML less or equal filter.

There are 2 required input options.

 Input option "attribute": String that contains the attribute name 
 that controls the search.
 Input option  "value": String that contains the value of the 
 attribute.

 $return = $filter->lessOrEqual( { attribute => "uid", 
                                   value => "turkey" } );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.


=item B<approxMatch ( {OPTIONS} )>

The method approxMatch sets up a DSML approximate match filter.

There are 2 required input options.

 Input option "attribute": String that contains the attribute name 
 that controls the search.
 Input option  "value": String that contains the value of the 
 attribute.

 $return = $filter->approxMatch( { attribute => "uid", 
                                   value => "bird" } );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.


=item B<extensibleMatch ( {OPTIONS} )>

The method extensibleMatch sets up a DSML extensibleMatch filter.
 
There is 1 required input options.
There are 3 required optional options.
 
 $return = $filter->extensibleMatch( { value =>" ",
                                       name => " ",
                                       matchingRule => " ",
                                       dnAttributes => " " } );

Method output;  Returns true on success; false on error, error message 
can be gotten with error property.
 
Input option  "value": String that contains the value of the 
attribute.  Required.
Input option  "matchingRule": String that contains the value of the 
matchingRule.  Optional.
Input option  "dnAttributes": String that contains the boolean value 
of true or false.  Optional.
Input option  "name": String that contains the name string.  Optional.

=item B<or ()>

The method or sets up a beginning or element of a DSML or filter.

There are no required input options.

$return = $filter->or();

Method output;  Always returns true for success.


=item B<endor ()>

The method endor sets up a ending or element of a DSML or filter.

There are no required input options.

$return = $filter->endor();

Method output;  Always returns true for success.


=item B<and ()>

The method and sets up a beginning and element of a DSML and filter.

There are no required input options.

$return = $filter->and();

Method output;  Always return true for success.


=item B<endand ()>

The method endand sets up a ending and element of a DSML and filter.

There are no required input options.

$return = $filter->endand();

Method output;  Always returns true for success.


=item B<not ()>

The method not sets up a beginning not element of a DSML not filter.

There are no required input options.

$return = $filter->not();

Method output;  Always return true for success.


=item B<endnot ()>

The method endnot sets up the ending not element of a DSML not filter.

There are no required input options.

$return = $filter->endnot();

Method output;  Always returns true for success.

=back

=head1 DIAGNOSTICS

All of the error messages should be self explantory.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Net::DSML::filter requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module depends on the following modules.

=over 4
        Test::More          => 0
        version             => 0.680
        Readonly            => 1.030
        Class::Std::Utils   => 0.0.2
        LWP::UserAgent      => 2.0
        Carp                => 1.040

=back

=head1 INCOMPATIBILITIES

None known or reported.


=head1 BUGS AND LIMITATIONS

No known limitations.
No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-clif@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 GENERAL

Since the script is in PERL, feel free to modify it if it does not
meet your needs.  This is one of the main reasons I did it in PERL.
If you make an addition to the code that you feel other individuals
could use let me know about it.  I may incorporate your code
into my code.

=head1 AUTHOR

Clif Harden  C<< <charden@pobox.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Clif Harden C<< <charden@pobox.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
