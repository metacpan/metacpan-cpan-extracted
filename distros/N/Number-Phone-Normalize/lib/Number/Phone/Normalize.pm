package Number::Phone::Normalize;

use strict;
use warnings;

use Carp;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(phone_intl phone_local);

our $VERSION = '0.220';

sub _kill_vanity {
  my $number = shift;
  $number =~ s/[abc]/2/gi;
  $number =~ s/[def]/3/gi;
  $number =~ s/[ghi]/4/gi;
  $number =~ s/[jkl]/5/gi;
  $number =~ s/[mno]/6/gi;
  $number =~ s/[pqrs]/7/gi;
  $number =~ s/[tuv]/8/gi;
  $number =~ s/[wxyz]/9/gi;
  return $number;
}

sub _remove_prefix {
  my ($number,$prefix) = @_;
  $number = _kill_vanity($number); $number =~ s/[^0-9]//g;
  $prefix = _kill_vanity($prefix); $prefix =~ s/[^0-9]//g;

  if ($number =~ m/^$prefix/) {
    for(my $i=0;$i<length($prefix);$i++) {
      $_[0] =~ s/^[^0-9A-Z]*[0-9A-Z][^0-9A-Z]*//i;
    }
    return $_[0];
  } else {
    return undef;
  }
}

sub new {
  my($class,%param) = @_;
  my $self = bless {}, ref($class) || $class;

  %{$self} = %{$class} if (ref $class);

  foreach(keys %param)
  {
    if(my $accessor = $self->can($_))
    {
      &$accessor($self,$param{$_})
    }else{
      croak "Invalid parameter: $_";
    }
  }

  return $self;
}

sub _self {
  my($self,%param) = @_;
  
  return new(__PACKAGE__,%param) unless ref($self);
  return $self->new(%param) if %param;
  return $self;
}

sub intl {
  my ($self,$number,%param) = @_;
  $self = _self($self,%param);

  my $has_prefix = ($number =~ m/^[^A-Z0-9]*\+/i);

  $number = _kill_vanity $number unless $self->VanityOK;

  $number =~ s/[^0-9A-Z]+/ /gi;		# Normalize Punctuation
  $number =~ s/^ *(.*?) *$/$1/;		# Remove leading/trailing Whitespace

  return '+'.$number if $has_prefix;	# Number was alreads in int'l format
  return undef unless $number;		# no significant digits

  my $nn;

  if($nn = _remove_prefix($number,$self->IntlPrefix)) {
    return '+'.$nn;
  } 
  elsif(($nn = _remove_prefix($number,$self->LDPrefix)) && defined $self->CountryCode) {
    return '+'.($self->CountryCode).' '.$nn;
  }
  elsif(defined $self->CountryCode && defined $self->AreaCode) {
    return '+'.($self->CountryCode).' '.($self->AreaCode).' '.$number;
  } 
  return undef;
}

sub local {
  my ($self,$number,%param) = @_;
  $self = _self($self,%param);

  my $has_prefix = ($number =~ m/^[^A-Z0-9 ]*\+/i);

  $number = _kill_vanity $number unless $self->VanityOK;
  $number =~ s/[^0-9A-Z]+/ /gi;		# Normalize Punctuation
  $number =~ s/^ *(.*?) *$/$1/;		# Remove leading/trailing Whitespace

  return undef unless $number ne '';	# no significant digits

  my $nn;

  if($has_prefix) {
    #
    # Number is in international format
    #
    if(defined $self->CountryCodeOut && defined $self->AreaCodeOut && (!$self->AlwaysLD) 
        && ($nn = _remove_prefix($number,($self->CountryCodeOut).($self->AreaCodeOut)))) {
      return $nn;
    } 
    elsif($self->CountryCodeOut 
        && ($nn = _remove_prefix($number,$self->CountryCodeOut))) {
      return ($self->LDPrefixOut).$nn;
    } 
    else {
      return ($self->IntlPrefixOut).$number
    }
  } else {
    #
    # Number is in local format
    
    @_ = ($self, $self->intl($number));
    goto &local unless !defined $_[1];
    
    if(defined $self->AreaCodeOut && (!$self->AlwaysLD)
        && ($nn = _remove_prefix($number,($self->LDPrefix).($self->AreaCodeOut)))) {
      return $nn;
    }
    elsif(($nn = _remove_prefix($number,($self->LDPrefix)))) {
      return ($self->LDPrefixOut).$nn;
    }
    elsif(defined $self->AreaCode && defined $self->AreaCodeOut 
        && $self->AreaCode ne $self->AreaCodeOut) {
      return ($self->LDPrefixOut).($self->AreaCode).' '.$number
    }
    elsif($self->AlwaysLD && defined $self->AreaCodeOut)
    {
      return ($self->LDPrefixOut).($self->AreaCodeOut).' '.$number
    }
    else
    {
      return $number;
    }
  }
}

sub IntlPrefix { 
  my $self = shift;
  my $old_value = defined $self->{'IntlPrefix'} ? $self->{'IntlPrefix'} : '00';
  $self->{'IntlPrefix'} = shift if @_;
  return $old_value;
}

sub LDPrefix { 
  my $self = shift;
  my $old_value = defined $self->{'LDPrefix'} ? $self->{'LDPrefix'} : '0';
  $self->{'LDPrefix'} = shift if @_;
  return $old_value;
}

sub IntlPrefixOut { 
  my $self = shift;
  my $old_value = defined $self->{'IntlPrefixOut'} ? $self->{'IntlPrefixOut'} : $self->IntlPrefix;
  $self->{'IntlPrefixOut'} = shift if @_;
  return $old_value;
}

sub LDPrefixOut { 
  my $self = shift;
  my $old_value = defined $self->{'LDPrefixOut'} ? $self->{'LDPrefixOut'} : $self->LDPrefix;
  $self->{'LDPrefixOut'} = shift if @_;
  return $old_value;
}

sub CountryCode {
  my $self = shift;
  my $old_value = $self->{'CountryCode'};
  $self->{'CountryCode'} = shift if @_;
  return $old_value;
}

sub AreaCode {
  my $self = shift;
  my $old_value = $self->{'AreaCode'};
  $self->{'AreaCode'} = shift if @_;
  return $old_value;
}

sub CountryCodeOut {
  my $self = shift;
  my $old_value = defined $self->{'CountryCodeOut'} ? $self->{'CountryCodeOut'} : $self->CountryCode;
  $self->{'CountryCodeOut'} = shift if @_;
  return $old_value;
}

sub AreaCodeOut {
  my $self = shift;
  my $old_value = $self->{'AreaCodeOut'} ? $self->{'AreaCodeOut'} : $self->AreaCode;
  $self->{'AreaCodeOut'} = shift if @_;
  return $old_value;
}

sub VanityOK {
  my $self = shift;
  my $old_value = $self->{'VanityOK'};
  $self->{'VanityOK'} = shift if @_;
  return $old_value;
}

sub AlwaysLD {
  my $self = shift;
  my $old_value = $self->{'AlwaysLD'} && defined $self->AreaCodeOut;
  $self->{'AlwaysLD'} = shift if @_;
  return $old_value;
}

sub phone_intl { unshift @_, undef; goto &intl; }
sub phone_local { unshift @_, undef; goto &local; }

1;

__END__

=head1 NAME

Number::Phone::Normalize - Normalizes format of Phone Numbers.

=head1 SYNOPSIS

  use Number::Phone::Normalize;

  print phone_intl('+1 (555)  123     4567');			# +1 555 1234567
  print phone_local('+49-89-99999999','CountryCode'=>'49');	# 089 99999999

=head1 DESCRIPTION

This module takes a phone (or E.164) number in different input formats and
outputs it in accordance to E.123 or in local formats.

=head2 FUNCTIONS

=over

=item phone_intl( $number, %params )

Normalizes the phone number $number and returns it in international (E.164)
format. $number can be in an international format or in a local format if the
C<CountryCode>/C<AreaCode> parameters are supplied.

If C<phone_intl> does not have enough information to build an international
number (e.g. C<$number> does not contain a country code and C<%param> does not
specify a default), it returns C<undef>.

=item phone_local( $number, %params )

Normalizes the phone number $number and returns it in local format. $number can
be in an international format or in a local format if the C<CountryCode>/C<AreaCode>
parameters are supplied. 

If C<phone_local> does not have enough information to build an international
number (e.g. C<$number> does not contain a country code and C<%param> does not
specify a default), it returns C<undef>.

=back

=head2 METHODS

There is also an object-oriented interface, which allows you to specify the
parameters once, in the constructor.

=over

=item new( %params )

Creates an object that carries default parameters:

  $nlz = Number::Phone::Normalize->new( %params );

=item $nlz->intl( $number [, %more_params] )

=item $nlz->local( $number [, %more_params] )

These functions are equivalent to C<phone_intl> and
C<phone_local> but use the C<%params> passed to C<new> as default.

I.e., the following calls:
  
  Number::Phone::Normalize->new( %p1 )->intl( $number, %p2 )
  Number::Phone::Normalize->new( %p1 )->local( $number, %p2 )

are equivalent to the follwoing:

  phone_intl( $number, %p1, %p2 );
  phone_local( $number, %p1, %p2 );

=back

=head2 COMMON PARAMETERS

All functions, constructors and methods take the following parameters.
Parameters specified in method calls override those given to the constructor.

=head3 for input

These parameters specify how the input C<$number> is interpreted if it is in a
non-international format.

=over

=item C<CountryCode>

The local country code. It is added to phone numbers in local format without an
country code.

=item C<AreaCode>

The local area code. It is added to phone numbers in local format without an
area code.

=item C<IntlPrefix>

The international prefix. If C<$number> starts with this prefix, the country code
and area code are taken from the number.

The default is '00' (ITU recommendation).

=item C<LDPrefix>

The long distance prefix. If $number starts with this prefix, the area code is
taken from $number and the country code is taken from the C<CountryCode>
parameter.

If $number starts with neither C<IntlPrefix> nor C<LDPrefix>, it is assumed to
be in local format and both country and area codes are taken from the
parameters.

The default is '0' (ITU recommendation).

=back

=head3 for output

These parameters control formatting of the output.
Most parameters only affect output in local format.

=over

=item CountryCodeOut

The local country code. If the number does not have the C<CountryCode> specified,
it is returned starting with the C<IntlPrefix>.

=item AreaCodeOut

The local country code. If the number does not have the C<CountryCode> specified,
it is returned starting with the C<LDPrefix>.

=item C<IntlPrefixOut>

The international prefix for output. If the number is not in the country
specified by C<CountryCode>, the returned number will start with this prefix.

The default is C<IntlPrefix>.

You can set this parameter to '+' in order to return numbers in international
format instead of the local format.

=item C<LDPrefixOut>

The long distance prefix for output. It the number is not in the area specified
by C<AreaCode> or C<AlwaysLD> is set to true, it is returned starting with C<LDPrefixOut>.

The default is LDPrefix.

=item C<AlwaysLD>

If set to true, the number will always be returned with an area code, even if
it is in the country and area specified by C<CountryCode> and C<AreaCode>.

=item C<VanityOK>

If set to true, vanity numbers will not be converted to numeric format.

=back

=head1 BUGS AND LIMITATIONS

The module does not support more complex dialling plans. It is
mostly intended for data input and output (especially to and from
databases), but not to prepare numbers for dialling.

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2004-2009 Claus FE<auml>rber.

It is free software; you can redistribute it and/or modify it
under the same terms as perl itself, either version 5.5.0 or, at
your option, any later version.

=cut
