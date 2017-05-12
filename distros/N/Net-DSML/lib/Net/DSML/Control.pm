package Net::DSML::Control;

use warnings;
use strict;
#use Carp;
use Class::Std::Utils;

# Copyright (c) 2007 Clif Harden <charden@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use version; $VERSION = version->new('0.002');

{

BEGIN
{
  use Exporter ();

  @ISA = qw(Exporter);
  @EXPORT = qw();
  %EXPORT_TAGS = ();
  @EXPORT_OK  = ();
}

my %errMsg;        # no error this will be a null string.
my %controls;      # Actual xml data string.
my %default;       # will contain the initial control string if there is one.
#
# Method new
#
# The method new creates a new DSML Control oject.
#
# There are four possible input options.
# Input option "control":   Sets the oid number of the control
# Input option "value":  Sets the control value data.
# Input option "valuetype":    Sets the xsd type for the control value.
# Input option "criticality":   Sets the criticality variable to the input 
# value, either true or false.
#
#
# $control = Net::DSML::Control->new( { control => 1.2.840.113556.1.4.619, 
#                                       valuetype => base64Binary, 
#                                       criticality => true, 
#                                       value => RFNNTYyLJA==  } );
#
# Method output;  Returns a new DSML object.
#

sub new
{
  my ($class, $opt) = @_;
  my $self = bless anon_scalar(),$class;
  my $id = ident($self);
  my $result;
  my $value;
  my $valuetype;
  my $criticality;
  my $control;
  #
  # Initailize data to a default values.
  #
  $errMsg{$id} = "";     # no error 
  $controls{$id}   = []; # Actual control xml data string(s).
  $default{$id}->{default} = "";

  if ( $opt )
  {

  if ( !defined($opt->{control}) )
  {
    $errMsg{$id} = "Subroutine Control required type oid value is not defined.";
    return $self;
  }

  $control = (ref($opt->{control}) ? ${$opt->{control}} : $opt->{control});
  $valuetype = (ref($opt->{valuetype}) ? ${$opt->{valuetype}} : $opt->{valuetype}) if ( $opt->{valuetype});
  $criticality = (ref($opt->{criticality}) ? ${$opt->{criticality}} : $opt->{criticality}) if ( $opt->{criticality});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});

  if ( $opt->{criticality} && !($criticality =~ /^(true)||(false)$/) )
  {
    $errMsg{$id} = "The Control`s criticality is not defined properly.";
    return $self;
  }

  if ( $opt->{valuetype} && !($valuetype =~ /^(string)||(anyURI)||(base64Binary)$/) )
  {
    $errMsg{$id} = "The Control`s valuetype is not defined properly.";
    return $self;
  }

  if (  $opt->{value} && !$opt->{valuetype})
  {
    $errMsg{$id} = "The value data was defined but the valuetype of the value data was not not defined.";
    return $self;
  }

  if ( $opt->{type} && !$opt->{value})
  {
    $errMsg{$id} = "The valuetype was defined but the value data was not not defined.";
    return $self;
  }

  if ( $opt->{value} )
  {
    _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
  }

  $result = "<control type=\"". $control . "\"";
  $result .= " critical=\"" . $criticality . "\"" if ( $opt->{criticality});
  $result .= ">";
  $result .=  "<controlValue " if ($opt->{value});
  $result .= "xsi:type=\"xsd:" . $valuetype . "\"" if ( $opt->{value} && $opt->{valuetype});
  $result .= ">" if ( $opt->{value} && $opt->{valuetype});
  $result .= $value . "</controlValue>" if ($opt->{value});
  $result .= "</control>";

  push(@{$controls{$id}}, $result);
  $default{$id}->{default} = $result;
  }

return $self;
}

#
# inside-out classes have to have a DESTROY subrountine.
#
sub DESTROY
{
  my ($dsml) = @_;
  my $id = ident($dsml);

  delete $controls{$id};      # Copy of actual xml data string.
  delete $default{$id};       # Copy of actual xml data string.
  delete $errMsg{$id};        # no error this will be a null string.
  return;
}

#
# The method clear sets object variables to their default values.
#
# Returns true on success.  
#

sub clear
{
  my ($dsml) = shift;
  my $id = ident $dsml;

  $controls{$id} = [];  # Actual xml data string.
  $errMsg{$id}   = "";  # error messages, no error this will be a null string.
  push(@{$controls{$id}}, $default{$id}->{default});
  return 1;
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
  return;
}

#
# Method error
#
# The method error returns the error message for the object.
# $message = $dsml->error();
#

sub error
{
  my $dsml = shift;
  return $errMsg{ident $dsml};
}

# Method add
# 
# The method Add is used in conjuction with other methods like Search.
# 
# If there is one required input option and 3 additional optional options.
# 
# $return = $control->Add( { control => 1.2.840.113556.1.4.619, valuetype => base64Binary, criticality => true, value => RFNNTYyLJA==  } );
# 
# Input option "control":  The control oid number.
# Input option "valuetype":  The xsd type for the value data.
# Input option "criticality":  The criticality of the control; true or false.
# Input option "value":  The value of the control.
# 
# Method output;  Returns true on success;  false on error, error message 
# can be gotten with error method.
# 

sub add
{
  my ($dsml, $opt) = @_;
  my $id = ident $dsml;
  my $result;
  my $value;
  my $valuetype;
  my $criticality;
  my $control;

  $errMsg{$id} = "";
  if ( !defined($opt->{control}) )
  {
    $errMsg{$id} = "Method add control required oid value is not defined.";
    return 0;
  }

  $control = (ref($opt->{control}) ? ${$opt->{control}} : $opt->{control});
  $valuetype = (ref($opt->{valuetype}) ? ${$opt->{valuetype}} : $opt->{valuetype}) if ( $opt->{valuetype});
  $criticality = (ref($opt->{criticality}) ? ${$opt->{criticality}} : $opt->{criticality}) if ( $opt->{criticality});
  $value = (ref($opt->{value}) ? ${$opt->{value}} : $opt->{value});


  if ( $opt->{criticality} && !($criticality =~ /^(true)||(false)$/) )
  {
    $errMsg{$id} = "Method add Control criticality is not defined properly.";
    return 0;
  }

  if ( $opt->{valuetype} && !($valuetype =~ /^(string)||(anyURI)||(base64Binary)$/) )
  {
    $errMsg{$id} = "Method add control`s valuetype is not defined properly.";
    return 0;
  }

  if (  $opt->{value} && ! $opt->{valuetype})
  {
    $errMsg{$id} = "Method control valuetype for the value data was not not defined.";
    return 0;
  }

  if ( $opt->{valuetype} && !$opt->{value})
  {
    $errMsg{$id} = "Method add control`s valuetype was defined but the value data was not not defined.";
    return 0;
  }

  if ( $opt->{value} )
  {
    _specialChar(\$value) if ( $value =~ /(&||<||>||"||')/);
  }

  $result = "<control type=\"". $control . "\"";
  $result .= " critical=\"" . $criticality . "\"" if ( $opt->{criticality});
  $result .= ">";
  $result .=  "<controlValue " if ($opt->{value});
  $result .= "xsi:type=\"xsd:" . $valuetype . "\"" if ( $opt->{value} && $opt->{valuetype});
  $result .= ">" if ( $opt->{value} && $opt->{valuetype});
  $result .= $value . "</controlValue>" if ($opt->{value});
  $result .= "</control>";
  
  push(@{$controls{$id}}, $result);
  return 1;
}

sub getControl
{
  my ($dsml) = @_;
  my $id = ident $dsml;
  my $result;
  $result = "";

  foreach my $var (@{$controls{$id}})
  {
     $result .= $var;
  }

  return $result;
}

}

1; # Magic true value required at end of module

__END__

=head1 NAME

Net::DSML::Control -  A perl module that supplies a Net::DSML::Control object that is used with a Net::DSML object.


=head1 VERSION

This document describes Net::DSML::Control version 0.002


=head1 SYNOPSIS

 Control examples.
 
 use Net::DSML;
 use Net::DSML::filter;
 use Net::DSML::Control;

 # Create a DSML Control object with one control.
 $dsmlControl = Net::DSML::Control->new( { oid => 1.2.840.113556.1.4.619,
                             type => base64Binary,
                             criticality => true,
                             value => RFNNTYyLJA==  } );


 Another form of control creation.

 use Net::DSML;
 use Net::DSML::filter;
 use Net::DSML::Control;

 # Create a DSML Control object with no controls.
 $dsmlControl = Net::DSML::Control->new();

 # Add a DSML Control.
 $dsmlControl->add( { control => 1.2.840.113556.1.4.619,
                      type => base64Binary,
                      criticality => true,
                      value => RFNNTYyLJA==  } );


=head1 DESCRIPTION

Net::DSML::Control is a module that supplies a LDAP
DSML Control object for a Net::DSML operation.

This document assumes that the reader has some knowledge of
the LDAP, LDAP Controls and DSML protocols.

=head1 INTERFACE

=over 1

=item B<new ( {OPTIONS} )>

The method new is the constructor for a new Net::DSML::Control oject.

There are two possible object construction options.

With input options.

 Input option "control":  The control oid number. Required.
 Input option "valuetype":  The xsd type for the value data.
                            Values base64Binary, string, anyURI
 Input option "criticality":  The criticality of the control; 
 true or false.
 Input option "value":  The value of the control.

 $dsml = Net::DSML::Control->new( { control => "1.2.840.113556.1.4.619", 
                             valuetype => "base64Binary", 
                             criticality => "true", 
                             value => "RFNNTYyLJA=="  } );

Method output;  Returns a Net::DSML::Control object.
If there is an error in the input options, get the error message 
with the error method.

Without input options.

 $dsml = Net::DSML::Control->new();

Method output;  Returns a new DSML object.

=item B<error ()>

The method error returns the error message for the object.
 $message = $dsml->error();

=item B<clear ()>

The method clear resets the object to its default values
 $result = $dsml->clear();
 $result will always contain a 1.

=item B<getControl ()>

The method getControls returns all of the controls for this object.

 $returnControls = $dsml->getControl();

=item B<add ( {OPTIONS} )>

Controls can be stack on top of another control.A
The method add can be used to add additional controls to the Control object.
 
If there is one required input option and 3 possible optional options.

 Input option "control":  The control oid number. Required.
 Input option "valuetype":  The xsd type for the value data.
                            Values base64Binary, string, anyURI
 Input option "criticality":  The criticality of the control; 
 true or false.
 Input option "value":  The value of the control.

 $return = $dsml->Control( { control => "1.2.840.113556.1.4.619", 
                             valuetype => "base64Binary", 
                             criticality => "true", 
                             value => "RFNNTYyLJA=="  } );

Method output;  Returns true (1) on success;  false (0) on error, error 
message can be gotten with error method.   Errors will pretain to
input options.

=back

=head1 DIAGNOSTICS

All of the error messages should be self explantory.


=head1 CONFIGURATION AND ENVIRONMENT

Net::DSML::Control requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over 4

        Test::More          => 0
        version             => 0.680
        Class::Std::Utils   => 0.0.2
        Carp                => 1.040

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Currently there is a limition concerning authentication, it has
not yet been implemented.  This rules out any operations that 
modify data or access to data that requires authentication to 
access data.

No bugs have been reported.

Please report any bugs or feature requests to
charden@pobox.com, or C<bug-net-dsml@rt.cpan.org>, or through 
the web interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Clif Harden  C<< <charden@pobox.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Clif Harden C<< <charden@pobox.com> >>. All rights reserved.

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
