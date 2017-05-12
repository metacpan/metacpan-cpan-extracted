#!/
# --------------------------------------
#
#   Title: Sub Starter
# Purpose: Creates a skeletal framework for Perl sub's.
#
#    Name: Sub::Starter
#    File: Starter.pm
# Created: July 25, 2009
#
# Copyright: Copyright 2009 by Shawn H Corey.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

# --------------------------------------
# Object
package Sub::Starter;

# --------------------------------------
# Pragmatics

require 5.008;

use strict;
use warnings;

use utf8;  # Convert all UTF-8 to Perl's internal representation.

# --------------------------------------
# Version
use version; our $VERSION = qv(v1.0.6);

# --------------------------------------
# Modules
use Carp;
use Data::Dumper;
use English qw( -no_match_vars ) ;  # Avoids regex performance penalty
use POSIX;
use Storable qw( dclone );

# --------------------------------------
# Configuration Parameters

my %Expand = (
  name        => sub { [ $_[0]{-name} ] },
  usage       => \&_fill_out_usage,
  parameters  => \&_fill_out_parameters,
  returns     => \&_fill_out_returns,
  definitions => \&_fill_out_definitions,
);

my %Selections = (
  are    => \&_fill_out_are,
  arenot => \&_fill_out_arenot,
  each   => \&_fill_out_each,
  first  => \&_fill_out_first,
  rest   => \&_fill_out_rest,
  list   => \&_fill_out_list,
);

my %Default_attributes = (
  -assignment        => q{''},
  -max_usage         => 0,
  -max_variable      => 0,
  -name              => '',
  -object            => '',
  -parameters        => [],
  -returns_alternate => '',
  -returns           => [],
);

my %String_escapes = (
  '\\' => '\\', # required, don't delete
  n => "\n",
  s => ' ',
  t => "\t",
);
my $String_escapes = join( '', sort keys %String_escapes );
$String_escapes =~ s{ \\ }{}gmsx;
$String_escapes = "[$String_escapes\\\\]";

my $RE_id         = qr{ [_[:alpha:]] [_[:alnum:]]* }mosx;
my $RE_scalar     = qr{ \A \$ ( $RE_id ) \z }mosx;
my $RE_array      = qr{ \A \@ ( $RE_id ) \z }mosx;
my $RE_hash       = qr{ \A \% ( $RE_id ) \z }mosx;
my $RE_scalar_ref = qr{ \A \\ \$ ( $RE_id ) \z }mosx;
my $RE_array_ref  = qr{ \A \\ \@ ( $RE_id ) \z }mosx;
my $RE_hash_ref   = qr{ \A \\ \% ( $RE_id ) \z }mosx;
my $RE_code_ref   = qr{ \A \\ \& ( $RE_id ) \z }mosx;
my $RE_typeglob   = qr{ \A \\? \* ( $RE_id ) \z }mosx;

# Make Data::Dumper pretty
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Maxdepth = 0;

# --------------------------------------
# Variables

# --------------------------------------
# Methods

# --------------------------------------
#       Name: new
#      Usage: $starter_sub = Sub::Starter->new( ; %attributes );
#    Purpose: To create a new object.
# Parameters:  %attributes -- keys must be in %Default_attributes
#    Returns: $starter_sub -- blessed hash
#
sub new {
  my $class = shift @_;
  my $self  = dclone( \%Default_attributes );

  $class = ( ref( $class ) or $class );
  bless $self, $class;
  $self->configure( @_ );

  return $self;
}

# --------------------------------------
#       Name: configure
#      Usage: $starter_sub->configure( %attributes );
#    Purpose: To (re)set the initial key-values pairs of the object.
# Parameters: %attributes -- keys must be in %Default_attributes
#    Returns: none
#
sub configure {
  my $self       = shift @_;
  my %attributes = @_;

  for my $attribute ( keys %attributes ){
    croak "unknown attribute '$attribute'" unless exists $Default_attributes{$attribute};
    $self->{$attribute} = $attributes{$attribute};
  }
}

# --------------------------------------
#       Name: get_attributes
#      Usage: %attributes = $starter_sub->get_attributes( ; @attribute_names );
#    Purpose: To retrieve the current value(s) of the attributes.
# Parameters: @attribute_names -- each must be a key in %Default_attributes
#    Returns:      %attributes -- current settings
#
sub get_attributes {
  my $self       = shift @_;
  my @attributes = @_;
  my %attributes = ();

  if( @attributes ){
    for my $attribute ( @attributes ){
      $attributes{$attribute} = $self->{$attribute} if exists $Default_attributes{$attribute};
    }
  }else{
    for my $attribute ( keys %Default_attributes ){
      $attributes{$attribute} = $self->{$attribute};
    }
  }

  return %attributes;
}

# --------------------------------------
#       Name: _parse_variable
#      Usage: %attr = _parse_variable( $parsed, $var );
#    Purpose: Find the attributes of a variable.
# Parameters: $parsed -- scratch pad for results
#                $var -- variable to parse
#    Returns:   %attr -- attributes of the variable
#
sub _parse_variable {
  my $parsed = shift @_;
  my $var    = shift @_;
  my $name   = '';
  my %attr   = ();

  $attr{-usage} = $var;
  $parsed->{-max_usage} = length $var if $parsed->{-max_usage} < length $var;

  if( $var =~ $RE_scalar ){
    $name = $1;
    $attr{-type} = 'scalar';
    $attr{-variable} = $attr{-usage};
  }elsif( $var =~ $RE_array ){
    $name = $1;
    $attr{-type} = 'array';
    $attr{-variable} = $attr{-usage};
  }elsif( $var =~ $RE_hash ){
    $name = $1;
    $attr{-type} = 'hash';
    $attr{-variable} = $attr{-usage};
  }elsif( $var =~ $RE_scalar_ref ){
    $name = $1; # . '_sref';
    $attr{-type} = 'scalar_ref';
    $attr{-variable} = '$' . $name;
  }elsif( $var =~ $RE_array_ref ){
    $name = $1; # . '_aref';
    $attr{-type} = 'array_ref';
    $attr{-variable} = '$' . $name;
  }elsif( $var =~ $RE_hash_ref ){
    $name = $1; # . '_href';
    $attr{-type} = 'hash_ref';
    $attr{-variable} = '$' . $name;
  }elsif( $var =~ $RE_code_ref ){
    $name = $1; # . '_cref';
    $attr{-type} = 'code_ref';
    $attr{-variable} = '$' . $name;
  }elsif( $var =~ $RE_typeglob ){
    $name = $1; # . '_gref';
    $attr{-type} = 'typeglob';
    $attr{-variable} = '$' . $name;
  }else{
    croak "unknown variable type: $var";
  }

  my $length = length( $name ) + 1;
  $parsed->{-max_variable} = $length if $parsed->{-max_variable} < $length;
  return %attr;
}

# --------------------------------------
#       Name: _parse_returns
#      Usage: _parse_returns( $parsed, $returns_part );
#    Purpose: Parse the sub's return variables
# Parameters:       $parsed -- storage hash
#             $returns_part -- part of the usage statement before the assignment
#    Returns: none
#
sub _parse_returns {
  my $parsed  = shift @_;
  my $returns = shift @_;
  my $list_var = 0;
  my %seen = ();

  return unless length $returns;

  if( $returns =~ s{ \+\= \z }{}msx ){
    $parsed->{-assignment} = 0;
  }else{
    $returns =~ s{ \= \z }{}msx;
  }

  if( $returns =~ m{ \A ( ([^\|]*) \| )? \( (.*?) \) \z }msx ){
    $parsed->{-returns_alternate} = $2;
    my $list = $3;

    if( $parsed->{-returns_alternate} ){
      $parsed->{-returns_alternate} = { _parse_variable( $parsed, $parsed->{-returns_alternate} ) };
      croak "alternative return variable is not a scalar" if $parsed->{-returns_alternate}{-type} ne 'scalar';
    }

    for my $var ( split m{ \, }msx, $list ){
      if( $seen{$var} ++ ){
        croak "Return parameter $var repeated";
      }
      my %attr = _parse_variable( $parsed, $var );
      push @{ $parsed->{-returns} }, { %attr };
      if( $attr{-type} eq 'array' or $attr{-type} eq 'hash' ){
        croak "array or hash may only occur at end of returns list" if $list_var ++;
      }
    }
  }elsif( $returns =~ m{ \A ([^\|]*) \| (.*?) \z }msx ){
    $parsed->{-returns_alternate} = $1;
    my $var = $2;

    $parsed->{-returns_alternate} = { _parse_variable( $parsed, $parsed->{-returns_alternate} ) };
    croak "alternative return variable is not a scalar" if $parsed->{-returns_alternate}{-type} ne 'scalar';
    if( $seen{$var} ++ ){
      croak "Return parameter $var repeated";
    }
    my %attr = _parse_variable( $parsed, $var );
    push @{ $parsed->{-returns} }, { %attr };
  }else{
    if( $seen{$returns} ++ ){
      croak "Return parameter $returns repeated";
    }
    my %attr = _parse_variable( $parsed, $returns );
    push @{ $parsed->{-returns} }, { %attr };
  }
  return;
}

# --------------------------------------
#       Name: _parse_parameters
#      Usage: _parse_parameters( $parsed, $param_part );
#    Purpose: Break the parameters into variables and store them.
# Parameters:     $parsed -- storage hash
#             $param_part -- part of the usage statement including optional parameters
#    Returns: none
#
sub _parse_parameters {
  my $parsed     = shift @_;
  my $param_part = shift @_;
  my $opt_params = '';
  my $list_var = 0;
  my %seen = ();

  if( $param_part =~ m{ \A ([^;]*) \; (.*) }msx ){
    $param_part = $1;
    $opt_params = $2;
  }

  for my $param ( split m{ \, }msx, $param_part ){
    if( $seen{$param} ++ ){
      die "Parameter $param repeated\n";
    }
    my %attr = _parse_variable( $parsed, $param );
    push @{ $parsed->{-parameters} }, { %attr };
    if( $attr{-type} eq 'array' or $attr{-type} eq 'hash' ){
      die "array or hash may only occur at end of parameter list" if $list_var ++;
    }
  }

  for my $param ( split m{ \, }msx, $opt_params ){
    if( $seen{$param} ++ ){
      die "Parameter $param repeated\n";
    }
    my %attr = _parse_variable( $parsed, $param );
    push @{ $parsed->{-parameters} }, { optional=>1, %attr };
    if( $attr{-type} eq 'array' or $attr{-type} eq 'hash' ){
      die "array or hash may only occur at end of parameter list" if $list_var ++;
    }
  }

  return;
}

# --------------------------------------
#       Name: parse_usage
#      Usage: $sub_starter->parse_usage( $usage_statement );
#    Purpose: Parse a usage statement and store its contents.
# Parameters: $usage_statement -- See POD for details
#    Returns: none
#
sub parse_usage {
  my $self            = shift @_;
  my $usage_statement = shift @_;
  my $usage = $usage_statement;

  # create a scratch pad
  my $parsed = dclone( \%Default_attributes );

  # clean up for easier processing
  $usage =~ s{ \s+ }{}gmsx;
  $usage =~ s{ \)? \;? \z }{}msx;

  # find returns via an assignment symbol
  my $returns_part = '';
  my $func_part = $usage;
  if( $usage =~ m{ \A ( [^=]* \= ) (.*) }msx ){
    $returns_part = $1;
    $func_part = $2;
  }
  if( $func_part =~ m{ = }msx ){
    croak "Multiple assignments in usage statement";
  }

  # get the name and possible object
  my $name_part = $func_part;
  my $param_part = '';
  if( $name_part =~ m{ \A ( [^()]* ) \( ( .*? ) \)? \z }msx ){
    $name_part = $1;
    $param_part = $2;
  }
  if( $name_part =~ s{ \A (.*?) \-\> }{}msx ){
    $parsed->{-object} =  $1;
    $parsed->{-max_variable} = 5;
  }
  $name_part =~ s{ \A \& }{}msx;
  $parsed->{-name} = $name_part;

  # parse the rest
  _parse_returns( $parsed, $returns_part );
  _parse_parameters( $parsed, $param_part );

  # set the values
  $self->configure( %$parsed );

  # print "\n\nSub::Starter->parse_usage(): ", Dumper $usage_statement, $self;
  return;
}

# --------------------------------------
#       Name: _fill_out_usage
#      Usage: \@text = _fill_out_usage( $self );
#    Purpose: Create a usage statement
# Parameters:   $self -- parameters of the sub
#    Returns:  \@text -- the usage statement in an anonynous array
#
sub _fill_out_usage {
  my $self   = shift @_;
  my $text   = '';

  # alternative returns
  if( ref $self->{-returns_alternate} ){
    $text = $self->{-returns_alternate}{-usage} . ' | ';
  }

  # do returns
  if( @{ $self->{-returns} } > 0 ){
    $text .= '( ' if @{ $self->{-returns} } > 1;
    my @list = ();
    for my $return ( @{ $self->{-returns} } ){
      push @list, $return->{-usage};
    }
    $text .= join( ', ', @list ) . ' ';
    $text .= ') ' if @{ $self->{-returns} } > 1;
    if( $self->{-assignment} eq '0' ){
      $text .= '+= ';
    }else{
      $text .= '= ';
    }
  }

  # do object
  if( length $self->{-object} ){
    $text .= $self->{-object} . '->';
  }

  # do name
  $text .= $self->{-name} . '(';

  # do parameters
  if( @{ $self->{-parameters} } > 0 ){
    $text .= ' ';
    my @list = ();
    my @optional = ();
    for my $parameter ( @{ $self->{-parameters} } ){
      if( $parameter->{optional} ){
        push @optional, $parameter->{-usage};
      }else{
        push @list, $parameter->{-usage};
      }
    }
    $text .= join( ', ', @list );
    if( @optional ){
      $text .= '; ' . join( ', ', @optional );
    }
    $text .= ' ';
  }

  # finish
  $text .= ');';

  return [ $text ];
}

# --------------------------------------
#       Name: _fill_out_are
#      Usage: \@text = _fill_out_are( $max_len, $string, @list );
#    Purpose: Determine if there is a list
# Parameters: $string -- A string to return
#               @list -- a list to test
#    Returns:  \@text -- array of the string or undef
#
sub _fill_out_are {
  my $max_len = shift @_;
  my $string = shift @_;
  my @list   = @_;

  return unless @list;

  if( defined $string ){
    $string =~ s{ \\ ($String_escapes) }{$String_escapes{$1}||$1}egmsx;
  }else{
    $string = '';
  }

  return [ $string ];
}

# --------------------------------------
#       Name: _fill_out_arenot
#      Usage: \@text = _fill_out_arenot( $max_len, $string, @list );
#    Purpose: Determine if there isn't a list
# Parameters: $string -- A string to return
#               @list -- a list to test
#    Returns:  \@text -- array of the string or undef
#
sub _fill_out_arenot {
  my $max_len = shift @_;
  my $string = shift @_;
  my @list   = @_;

  return if @list;

  if( defined $string ){
    $string =~ s{ \\ ($String_escapes) }{$String_escapes{$1}||$1}egmsx;
  }else{
    $string = '';
  }

  return [ $string ];
}

# --------------------------------------
#       Name: _fill_out_each
#      Usage: \@text = _fill_out_each( $max_len, $format, @list );
#    Purpose: Apply the format to all items in the list.
# Parameters: $format -- How to display the items
#               @list -- The list
#    Returns:  \@text -- Formatted items
#
sub _fill_out_each {
  my $max_len = shift @_;
  my $format = shift @_ || '%s';
  my @list   = @_;
  my $text   = undef;

  return unless @list;

  $format =~ s{ \\ ($String_escapes) }{$String_escapes{$1}||$1}egmsx;

  # print 'each: ', Dumper $format, \@list;
  if( $format =~ m{ \* }msx ){
    $text = [ map { sprintf( $format, $max_len, $_ ) } @list ];
  }else{
    $text = [ map { sprintf( $format, $_ ) } @list ];
  }

  return $text;
}

# --------------------------------------
#       Name: _fill_out_first
#      Usage: \@text = _fill_out_first( $max_len, $format, @list );
#    Purpose: Apply the format to the first item of the list.
# Parameters: $format -- How to display the items
#               @list -- The list
#    Returns:  \@text -- Formatted items
#
sub _fill_out_first {
  my $max_len = shift @_;
  my $format = shift @_;
  my @list   = @_;

  return unless @list;

  return _fill_out_each( $max_len, $format, $list[0] );
}

# --------------------------------------
#       Name: _fill_out_rest
#      Usage: \@text = _fill_out_rest( $max_len, $format, @list );
#    Purpose: Apply the format to all but the first item of the list.
# Parameters: $format -- How to display the items
#               @list -- The list
#    Returns:  \@text -- Formatted items
#
sub _fill_out_rest {
  my $max_len = shift @_;
  my $format = shift @_;
  my @list   = @_;

  return unless @list;

  return _fill_out_each( $max_len, $format, @list[ 1 .. $#list ] );
}

# --------------------------------------
#       Name: _fill_out_list
#      Usage: \@text = _fill_out_list( $max_len, $separator, @list );
#    Purpose: Create a string of the list
# Parameters: $separator -- What to join with
#                  @list -- List ot join
#    Returns:     \@text -- Array of the string
#
sub _fill_out_list {
  my $max_len   = shift @_;
  my $separator = shift @_ || ' ';
  my @list      = @_;

  return [ join( $separator, @list ) ];
}

# --------------------------------------
#       Name: _fill_out_parameters
#      Usage: \@text = _fill_out_parameters( $self, $selection, $format );
#    Purpose: Create a list of formatted, selected parameters.
# Parameters:      $self -- contains parameter list
#             $selection -- a subset of the parameters
#                $format -- how to display
#    Returns:     \@text -- formatted, selected parameters
#
sub _fill_out_parameters {
  my $self      = shift @_;
  my $selection = shift @_;
  my $format    = shift @_;

  my @list = map { $_->{-usage} } @{ $self->{-parameters} };
  #print 'parameters: ',Dumper \@list;

  if( exists $Selections{$selection} ){
    return &{ $Selections{$selection} }( $self->{-max_usage}, $format, @list );
  }else{
    carp "no selection for '$selection', skipped";
    return;
  }
}

# --------------------------------------
#       Name: _fill_out_returns_expression
#      Usage: \@text = _fill_out_returns_expression( $self );
#    Purpose: Create the return expression for tits statement.
# Parameters:  $self -- essential data
#    Returns: \@text -- string in an array
#
sub _fill_out_returns_expression {
  my $self = shift @_;
  my $text = ' ';

  return [''] unless @{ $self->{-returns} };

  # print 'expression: ', Dumper $self;
  my $returns = '';
  if( @{ $self->{-returns} } > 1 ){
    $returns = '( ' . join( ', ', map { $_->{-variable} } @{ $self->{-returns} } ) . ' )';
  }else{
    $returns = $self->{-returns}[0]{-variable};
  }

  if( $self->{-returns_alternate} ){
    $text .= "wantarray ? $returns : $self->{-returns_alternate}{-variable}";
  }else{
    $text .= $returns;
  }

  return [ $text ];
}

# --------------------------------------
#       Name: _fill_out_returns
#      Usage: \@text = _fill_out_returns( $self, $selection, $format );
#    Purpose: Create a list of formatted, selected returns.
# Parameters:      $self -- contains returns list
#             $selection -- a subset of the returns
#                $format -- how to display
#    Returns:     \@text -- formatted, selected returns
#
sub _fill_out_returns {
  my $self      = shift @_;
  my $selection = shift @_;
  my $format    = shift @_;
  my $text      = [];

  my @list = map { $_->{-usage} } @{ $self->{-returns} };
  if( $self->{-returns_alternate} ){
    unshift @list, $self->{-returns_alternate}{-usage};
  }
  #print 'returns: ',Dumper \@list;

  if( $selection eq 'expression' ){
    return _fill_out_returns_expression( $self );
  }elsif( exists $Selections{$selection} ){
    return &{ $Selections{$selection} }( $self->{-max_usage}, $format, @list );
  }else{
    carp "no selection for '$selection', skipped";
    return;
  }

  return $text;
}

# --------------------------------------
#       Name: _fill_out_definitions
#      Usage: \@text = _fill_out_definitions( $self, $format );
#    Purpose: Create a list of formatted, selected definitions.
# Parameters:      $self -- contains parameter and returns list
#                $format -- how to display
#    Returns:     \@text -- formatted, selected definitions
#
sub _fill_out_definitions {
  my $self      = shift @_;
  my $format    = shift @_ || '%s = %s';
  my @list      = ();
  my $text      = [];
  my %seen = ();

  # print 'self: ', Dumper $self;

  $format =~ s{ \\ ($String_escapes) }{$String_escapes{$1}||$1}egmsx;

  # do parameters
  if( $self->{-object} ){
    push @list, {
      -name     => 'self',
      -variable => '$self',
      -type     => 'scalar',
      -usage    => '$self'
    };
  }
  push @list, @{ $self->{-parameters} };

  # print 'parameters @list ', Dumper \@list, $format;
  for my $item ( @list ){
    next if $seen{$item->{-variable}} ++;
    my $value = 'shift @_';
    $value .= " || $self->{-assignment}" if $item->{optional};
    if( $item->{-type} eq 'array' || $item->{-type} eq 'hash' ){
      $value = '@_';
    }
    if( $format =~ m{ \* }msx ){
      push @$text, sprintf( $format, $self->{-max_variable}, $item->{-variable}, $value );
    }else{
      push @$text, sprintf( $format, $item->{-variable}, $value );
    }
  }

  # do returns
  @list = ();
  if( $self->{-returns_alternate} ){
    push @list, $self->{-returns_alternate};
  }
  push @list, @{ $self->{-returns} };

  # print 'returns @list ', Dumper \@list;
  for my $item ( @list ){
    next if $seen{$item->{-variable}} ++;
    my $value = $self->{-assignment};
    if( $item->{-type} eq 'scalar' ){
      # value already set
    }elsif( $item->{-type} eq 'array' || $item->{-type} eq 'hash' ){
      $value = '()';
    }elsif( $item->{-type} eq 'array_ref' ){
      $value = '[]';
    }elsif( $item->{-type} eq 'hash_ref' ){
      $value = '{}';
    }else{
      $value = 'undef';
    }
    if( $format =~ m{ \* }msx ){
      push @$text, sprintf( $format, $self->{-max_variable}, $item->{-variable}, $value );
    }else{
      push @$text, sprintf( $format, $item->{-variable}, $value );
    }
  }

  return $text;
}

# --------------------------------------
#       Name: fill_out
#      Usage: $text = $sub_starter->fill_out( \@template );
#    Purpose: Fill out the template with the current parameters
# Parameters: \@template -- List of lines with replacements
#    Returns:      $text -- resulting text
#
sub fill_out {
  my $self     = shift @_;
  my $template = shift @_;
  my $text     = '';

  for my $template_line ( @$template ){
    my $line = $template_line;  # copy to modify

    if( $line =~ m{ \A (.*?) \e\[1m \( ([^\)]*) \) \e\[0?m (.*) }msx ){
      my $front = $1;
      my $item = $2;
      my $back = $3;
      my ( $directive, @arguments ) = split m{ \s+ }msx, $item;

      my $expansion; # array reference
      if( exists $Expand{$directive} ){
        $expansion = &{ $Expand{$directive} }( $self, @arguments );
      }else{
        carp "no expansion for '$directive'";
        next;
      }

      for my $expanded ( @$expansion ){
        $text .= $front . $expanded . $back;
      }

    }else{
      $text .= $line;
    }
  }

  return $text;
}

1;
__DATA__
__END__

=head1 NAME

Sub::Starter - Creates a skeletal framework for Perl sub's.

=head1 VERSION

This document refers to Sub::Starter version v1.0.6

=head1 SYNOPSIS

  use Sub::Starter;

=head1 DESCRIPTION

This module is for providing a simple and consist way of
creating sub's.  It provides methods for loading the
interface to a sub and, using a template, output its
skeleton.  This skeleton can then be populate with code.

=head2 Usage Statements

A usage statement shows how a sub will be used.  It is used
by the C<parse_usage()> method.  It is not valid Perl.  It
uses the make-a-reference-to notation for references.  This
is to give a clear indication of what the references is to.

The following variables can be used for the parameters,
including the optional ones, and the returns;

=over 4

=item $scalar -- a scalar variable

=item @array -- an array variable or list

=item %hash -- a hash variable or list

=item \$scalar -- a reference to a scalar

=item \@array -- a reference to a array

=item \%hash -- a reference to a hash

=item \&code -- a reference to code

=item \*typeglob -- a reference to a typeglob

=back

Usage statements are:

  [ [ returns_alternate '|' ] returns_list assignment ] [ object '->' ] name [ '(' parameter_list [ ';' optional_parameters ] ')'? ] ';'?

The C<returns_alternate> is a scalar.

The C<assignment> is one of: C<=>, C<.=>, or C<+=>

The C<returns_list> and the C<parameters_list> must be a
list of scalars and references except for the last element,
which can be an array or hash.  If the
C<optional_parameters> list is present, the
C<parameters_list> cannot end with an array or hash.
Instead, the C<optional_parameters> list can.  These lists
are variables separated by a comma.

=head3 Examples of usage statements

  $text | @text = trim( @text );

  \%options = $object->get_options( ; @option_names );

=head2 Templates

Templates are used by the C<fill_out()> method to determine
how the output will look.  They are array of lines.  Each
line may contain one, and only one, directive.  Lines
without directives are copied verbatim to the output.  Some
directives has arguments.  Directive are distinguished by
the sequence C<\e[1m(> and ending with C<)\e[0m> where C<\e>
means the ASCII ESCAPE character.  The directives are:

=over 4

=item The name directive

The C<name> directive is replaced with the name of the sub.
It has no arguments.

=item The usage directive

The C<usage> directive is replaced with the usage statement.
It has no arguments.

=item The parameters directive

This is used to list the parameters.
It has one mandatory argument and one optional one.
The mandatory argument tells how and how much to display.
It can be C<are>, C<arenot>, C<each>, C<first>, C<rest>, or C<list>.

If it is C<are> then the line is outputted if there are some
parameters.  It can have an optional format argument (see
below).

If it is C<arenot> then the line is outputted if there are
not any parameters.  It can have an optional format argument
(see below).

The C<list> argument replaces the directive with a list of
the parameters.  The optional argument is the list
separator.  The default separator is a single space.

The C<each> outputs the line for each item in the list.
The C<first> outputs the line for the first item in the list.
The C<rest> outputs the line for all but the first item in the list.
If their list is empty, the line is not outputted.
They have an optional argument that formats the variable in the output.

The format argument translate '\s', '\t', and '\n' into
space, tab, and newline characters respectively.  If it's
part of a listing, it can have '%s', '%*s', or '%-*s' to
determine how the item will be displayed.  The '%s' will
simply display it.  This is the default.  The '%*s' will
display it, right-justified in a column wide enough for the
widest item.  The '%-*s' will display it, left-justified in
a column wide enough for the widest item.

=item The returns directive

This is used to list the returns.  It takes the same
arguments as the C<parameters> directive.

In addition, it has the C<expression> argument that creates
an expression for a return statement.

=item The definitions directive

The definitions directive will output all the parameters and
returns, one per line with a Perl assignment.  It has an
optional format which may be '%s\s=\s%s', '%*s\s=%s', or
'%-*s\s=\s%s'.  The first is the default.  The second
right-justifies the variable.  The last left-justifies it.

=back

=head3 Example of template: sub

  # --------------------------------------
  #       Name: \e[1m(name)\e[0m
  #      Usage: \e[1m(usage)\e[0m
  #    Purpose: TBD
  # Parameters: (none)\e[1m(parameters arenot)\e[0m
  # Parameters: \e[1m(parameters first %*s)\e[0m -- TBD
  #             \e[1m(parameters rest %*s)\e[0m -- TBD
  #    Returns: (none)\e[1m(returns arenot)\e[0m
  #    Returns: \e[1m(returns first %*s)\e[0m -- TBD
  #             \e[1m(returns rest %*s)\e[0m -- TBD
  #
  sub \e[1m(name)\e[0m {
    my \e[1m(definitions %-*s\s=\s%s)\e[0m;

    return\e[1m(returns expression)\e[0m;
  }

=head3 Example of template: pod

  =head2 \e[1m(name)\e[0m()

  TBD

  =head3 Usage

    \e[1m(usage)\e[0m

  =head3 Parameters

  (none)\e[1m(parameters arenot)\e[0m
  =over 4\e[1m(parameters are \n)\e[0m
  =item \e[1m(parameters each %s\n\nTBD\n)\e[0m
  =back\e[1m(parameters are)\e[0m

  =head3 Returns

  (none)\e[1m(returns arenot)\e[0m
  =over 4\e[1m(returns are \n)\e[0m
  =item \e[1m(returns each %s\n\nTBD\n)\e[0m
  =back\e[1m(returns are)\e[0m

=head1 METHODS

=head2 new()

Create a new sub starter object.  This object is populated
with default variables for its attributes.  These should be
changed before any output is attempted.

=head3 Usage

  $starter_sub = Sub::Starter->new( ; %attributes );

=head3 Parameters

=over 4

=item %attributes

All this module's attributes start with a minus sign or a
space.  Those that start with a minus sign are part of its
API.  Those that start with a space are for internal storage
and should not be changed.

If the application needs to store information in the object,
start the key with an alphanumeric character.  If a derived
class needs an attribute, start it with two minus signs.

=over 4

=item -assignment

This is the value assign to the optional parameters when
they are not present in the sub's call.

=item -max_usage

This is the maximum length of a variable string used in the
usage statement.

=item -max_variable

This is the maximum length of a variable string used
internally within the sub.

=item -name

This is the name of the sub.  It should be a valid Perl
identifier.

=item -object

This is the name of the object for the sub if it's a method.
It should be a scalar, as C<$object>, or a module, as
C<Sub::Scalar>.

=item -parameters

This is a list of hashes describing the parameters.  Each
has a:

C<-type>: C<scalar>, C<array>, C<hash>, C<scalar_ref>,
C<array_ref>, C<hash_ref>, C<code_ref>, or C<typeglob>

C<-usage>: the name of the variable as it appears in the usage statement.

C<-variable>: the name of the variable as it appears inside the sub.

C<-optional>: whether the parameter is optional.

=item -returns_alternate

This is a reference to a hash describing the alternate
return.  It should be a scalar and is described the same way
as the parameters except it cannot be optional.  If it is,
then this attribute is the null string.

=item -returns

This is a list of hashes describing the returns.  They are
described the same way as the parameters except they cannot
be optional.

=back

=back

=head3 Returns

=over 4

=item $starter_sub

This is the new object blessed to the C<Sub::Starter> class.

=back

=head2 configure()

This method can set one or more of the attributes.

=head3 Usage

  $starter_sub->configure( %attributes );

=head3 Parameters

=over 4

=item %attributes

Same as in the L<new()> method.

=back

=head3 Returns

(none)

=head2 get_attributes()

Get tone or more attributes.

=head3 Usage

  %attributes = $starter_sub->get_attributes( ; @attribute_names );

=head3 Parameters

=over 4

=item @attribute_names

An optional list of attribute names.  If the list is empty,
all attributes are returned.

=back

=head3 Returns

=over 4

=item %attributes

A hash of the requested attributes and their values.

=back

=head2 parse_usage()

Parse an usage statement.
See L<Usage Statements>.

=head3 Usage

  $sub_starter->parse_usage( $usage_statement );

=head3 Parameters

=over 4

=item $usage_statement

A string showing how the sub is to be used.

=back

=head3 Returns

(none)

=head2 fill_out()

Fill out a template.
See L<Templates> for details on creating one.

=head3 Usage

  $text = $sub_starter->fill_out( \@template );

=head3 Parameters

=over 4

=item \@template

The template with one line per element of the array.

=back

=head3 Returns

=over 4

=item $text

The text created from the template.

=back

=head1 DIAGNOSTICS

(none)

=head1 CONFIGURATION AND ENVIRONMENT

(none)

=head1 INCOMPATIBILITIES

(none)

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Sub::Starter at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub::Starter>.
I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sub::Starter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Starter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sub-Starter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sub-Starter>

=item * Search CPAN

L<http://search.cpan.org/dist/Sub-Starter>

=back

=head1 SEE ALSO

(none)

=head1 ORIGINAL AUTHOR

Shawn H Corey  C<< <SHCOREY at cpan.org> >>

=head2 Contributing Authors

(Insert your name here if you modified this program or its documentation.
 Do not remove this comment.)

=head1 ACKNOWLEDGEMENTS

jethro at perlmonks.org for brainstroming its name.

=head1 COPYRIGHT & LICENCES

Copyright 2009 by Shawn H Corey.  All rights reserved.

=head2 Software Licence

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=head2 Document Licence

Permission is granted to copy, distribute and/or modify this document under the
terms of the GNU Free Documentation License, Version 1.2 or any later version
published by the Free Software Foundation; with the Invariant Sections being
ORIGINAL AUTHOR, COPYRIGHT & LICENCES, Software Licence, and Document Licence.

You should have received a copy of the GNU Free Documentation Licence
along with this document; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut
