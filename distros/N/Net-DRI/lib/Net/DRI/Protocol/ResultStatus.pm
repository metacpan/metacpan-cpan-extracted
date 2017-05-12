## Domain Registry Interface, Encapsulating result status, standardized on EPP codes
##
## Copyright (c) 2005,2006,2008-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::ResultStatus;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_ro_accessors(qw(is_success native_code code message lang next));

use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.25 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::ResultStatus - Encapsulate Details of an Operation Result (with Standardization on EPP) for Net::DRI

=head1 DESCRIPTION

An object of this class represents all details of an operation result as given back from the registry,
with standardization on EPP as much as possible, for error codes and list of fields available.

When an operation is done, data retrieved from the registry is also stored inside the ResultStatus object
(besides being available through C<$dri->get_info()>). It can be queried using the C<get_data()> and
C<get_data_collection> methods as explained below. The data is stored as a ref hash with 3 levels:
the first keys have as values a reference to another hash where keys are again associated with values
being a reference to another hash where the content (keys and values) depends on the registry, the operation
attempted, and the result.

Some data will always be there: a "session" first key, with a "exchange" subkey, will have a reference to
an hash with the following keys:

=over

=item duration_seconds

the duration of the exchange with registry, in a floating point number of seconds

=item raw_command

the message sent to the registry, as string

=item raw_reply

the message received from the registry, as string

=item result_from_cache

either 0 or 1 if these results were retrieved from L<Net::DRI> Cache object or not

=item object_action

name of the action that has been done to achieve these results (ex: "info")

=item object_name

name (or ID) of the object on which the action has been performed (not necessarily always defined)

=item object_type

type of object on which this operation has been done (ex: "domain")

=item registry, profile, transport, protocol

registry name, profile name, transport name+version, protocol name+version used for this exchange

=item trid

transaction ID of this exchange

=back

=head1 METHODS

=head2 is_success()

returns 1 if the operation was a success

=head2 code()

returns the EPP code corresponding to the native code (which depends on the registry)
for this operation (see RFC for full list and source of this file for local extensions)

=head2 native_code()

gives the true status code we got back from registry (this breaks the encapsulation provided by Net::DRI, you should not use it if possible)

=head2 message()

gives the message attached to the the status code we got back from registry

=head2 lang()

gives the language in which the message above is written

=head2 get_extended_results()

gives back an array with additionnal result information from registry, especially in case of errors. If no data, an empty array is returned.

This method was previously called info(), before C<Net::DRI> version 0.92_01

=head2 get_data()

See explanation of data stored in L</"DESCRIPTION">. Can be called with one or three parameters and always returns a single value (or undef if failure).

With three parameters, it returns the value associated to the three keys/subkeys passed. Example: C<get_data("domain","example.com","exist")> will return
0 or 1 depending if the domain exists or not, after a domain check or domain info operation.

With only one parameter, it will verify there is only one branch (besides session/exchange and message/info), and if so returns the data associated
to the parameter passed used as the third key. Otherwise will return undef.

Please note that the input API is I<not> the same as the one used for C<$dri->get_info()>.

=head2 get_data_collection()

See explanation of data stored in L</"DESCRIPTION">. Can be called with either zero, one or two parameters and may return a list or a single value
depending on calling context (and respectively an empty list or undef in case of failure).

With no parameter, it returns the whole data as reference to an hash with 2 levels beneath as explained in L</"DESCRIPTION"> in scalar context, or
the list of keys of this hash in list context.

With one parameter, it returns the hash referenced by the key given as argument at first level in scalar context,
or the list of keys of this hash in list context.

With two parameters, it walks down two level of the hash using the two parameters as key and subkey and returns the bottom hash referenced
in scalar context, or the list of keys of this hash in list context.

Please note that in all cases you are given references to the data itself, not copies. You should not try to modify it in any way, but just read it.

=head2 as_string()

returns a string with all details, with the extended_results part if passed a true value

=head2 print()

same as CORE::print($rs->as_string(0))

=head2 print_full()

same as CORE::print($rs->as_string(1))

=head2 trid()

in scalar context, gives the transaction id (our transaction id, that is the client part in EPP) which has generated this result,
in array context, gives the transaction id followed by other ids given by registry (example in EPP: server transaction id)

=head2 is_pending()

returns 1 if the last operation was flagged as pending by registry (asynchronous handling)

=head2 is_closing()

returns 1 if the last operation made the registry close the connection (should not happen often)

=head2 is(NAME)

if you really need to test some other codes (this should not happen often), you can using symbolic names
defined inside this module (see source).
Going that way makes sure you are not hardcoding numbers in your application, and you do not need
to import variables from this module to your application.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2008-2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

## We give symbolic names only to codes that are used in some modules
our %EPP_CODES=(
                COMMAND_SUCCESSFUL => 1000,
		COMMAND_SUCCESSFUL_PENDING => 1001, ## needed for async registries when action done correctly on our side
                COMMAND_SUCCESSFUL_END => 1500, ## after logout

                COMMAND_SYNTAX_ERROR => 2001,
                PARAMETER_VALUE_SYNTAX_ERROR => 2005,
                AUTHENTICATION_ERROR => 2200,
                AUTHORIZATION_ERROR => 2201,
                OBJECT_EXISTS   => 2302,
                OBJECT_DOES_NOT_EXIST => 2303,
                COMMAND_FAILED => 2400, ## Internal server error not related to the protocol
                COMMAND_FAILED_CLOSING => 2500, ## Same + connection dropped
		SESSION_LIMIT_EXCEEDED_CLOSING => 2502, ## useful for rate limiting problems

                GENERIC_SUCCESS => 1900, ## these codes are not defined in EPP RFCs, but provide a nice extension
                GENERIC_ERROR   => 2900, ##     19XX for ok (1900=Undefined success), 29XX for errors (2900=Undefined error)
               );

sub new
{
 my ($class,$type,$code,$eppcode,$is_success,$message,$lang,$info)=@_;
 my %s=(
        is_success  => (defined($is_success) && $is_success)? 1 : 0,
        native_code => $code,
        message     => $message || '',
        type        => $type, ## rrp/epp/afnic/etc...
        lang        => $lang || '?',
	'next'	    => undef,
        data        => {},
       );

 $s{code}=_eppcode($type,$code,$eppcode,$s{is_success});
 $s{info}=(defined $info && ref $info eq 'ARRAY')? $info : []; ## should we now put that instead in data->{session}->{registry}->{extra_info} or something like that ?
 bless(\%s,$class);
 return \%s;
}

sub trid
{
 my $self=shift;
 return unless (exists($self->{trid}) && (ref($self->{trid}) eq 'ARRAY'));
 return wantarray()? @{$self->{trid}} : $self->{trid}->[0];
}

sub get_extended_results { return @{shift->{info}}; }

sub get_data
{
 my ($self,$k1,$k2,$k3)=@_;
 if (! defined $k1 || (defined $k3 xor defined $k2)) { Net::DRI::Exception::err_insufficient_parameters('get_data() expects one or three parameters'); }
 my $d=$self->{'data'};

 ## 3 parameters form, walk the whole references tree
 if (defined $k2 && defined $k3)
 {
  if (! exists $d->{$k1})               { return; }
  ($k1,$k2)=Net::DRI::Util::normalize_name($k1,$k2);
  if (! exists $d->{$k1}->{$k2})        { return; }
  if (! exists $d->{$k1}->{$k2}->{$k3}) { return; }
  return $d->{$k1}->{$k2}->{$k3};
 }

 ## 1 parameter form, go directly to leafs if not too much of them (we skip session/exchange + message/info)
 my @k=grep { $_ ne 'session' && $_ ne 'message' } keys %$d;
 if (@k != 1) { return; }
 $d=$d->{$k[0]};
 if ( keys(%$d) != 1 ) { return; }
 ($d)=values %$d;
 if (! exists $d->{$k1}) { return; }
 return $d->{$k1};
}

sub get_data_collection
{
 my ($self,$k1,$k2)=@_;
 my $d=$self->{'data'};

 if (! defined $k1)             { return wantarray ? keys %$d : $d; }
 if (! exists $d->{$k1})        { return; }
 if (! defined $k2)             { return wantarray ? keys %{$d->{$k1}} : $d->{$k1}; }
 ($k1,$k2)=Net::DRI::Util::normalize_name($k1,$k2);
 if (! exists $d->{$k1}->{$k2}) { return; }
 return wantarray ? keys %{$d->{$k1}->{$k2}} : $d->{$k1}->{$k2};
}

sub last { my $self=shift; while ( defined $self->next() ) { $self=$self->next(); } return $self; }

## These methods are not public !
sub _set_trid { my ($self,$v)=@_; $self->{'trid'}=$v; }
sub _add_next { my ($self,$v)=@_; $self->{'next'}=$v; }
sub _add_last { my ($self,$v)=@_; while ( defined $self->next() ) { $self=$self->next(); } $self->{'next'}=$v; }
sub _set_data { my ($self,$v)=@_; $self->{'data'}=$v; }
sub _eppcode
{
 my ($type,$code,$eppcode,$is_success)=@_;
 return $EPP_CODES{GENERIC_ERROR} unless defined($type) && $type && defined($code);
 $eppcode=$code if (!defined($eppcode) && ($type eq 'epp'));
 return $is_success? $EPP_CODES{GENERIC_SUCCESS} : $EPP_CODES{GENERIC_ERROR} unless defined($eppcode);
 return $eppcode if ($eppcode=~m/^\d{4}$/);
 return $EPP_CODES{$eppcode} if exists($EPP_CODES{$eppcode});
 return $EPP_CODES{GENERIC_ERROR};
}

sub new_generic_success { my ($class,$msg,$lang,$ri)=@_;       return $class->new('epp',$EPP_CODES{GENERIC_SUCCESS},undef,1,$msg,$lang,$ri); }
sub new_generic_error   { my ($class,$msg,$lang,$ri)=@_;       return $class->new('epp',$EPP_CODES{GENERIC_ERROR},undef,0,$msg,$lang,$ri); }
sub new_success         { my ($class,$code,$msg,$lang,$ri)=@_; return $class->new('epp',$code,undef,1,$msg,$lang,$ri); }
sub new_error           { my ($class,$code,$msg,$lang,$ri)=@_; return $class->new('epp',$code,undef,0,$msg,$lang,$ri); }

sub as_string
{
 my ($self,$withinfo)=@_;
 my $b=sprintf('%s %d %s',$self->is_success()? 'SUCCESS' : 'ERROR',$self->code(),length $self->message() ? ($self->code() eq $self->native_code()? $self->message() : $self->message().' ['.$self->native_code().']') : '(No message given)');
 if (defined($withinfo) && $withinfo)
 {
  my @i=$self->get_extended_results();
  $b.="\n".join("\n",map { my $rh=$_; join(' ',map { $_.'='.$rh->{$_} } sort(keys(%$rh))) } @i) if @i;
 }
 return $b;
}

sub print      { print shift->as_string(0); }
sub print_full { print shift->as_string(1); }

sub is_pending { return (shift->code()==$EPP_CODES{COMMAND_SUCCESSFUL_PENDING})? 1 : 0; }
sub is_closing { my $c=shift->code(); return ($c==$EPP_CODES{COMMAND_SUCCESSFUL_END} || ($c>=2500 && $c<=2502))? 1 : 0; }

sub is
{
 my ($self,$symcode)=@_;
 return unless (defined $symcode && length $symcode && exists $EPP_CODES{$symcode});
 return ($self->code()==$EPP_CODES{$symcode})? 1 : 0;
}

####################################################################################################
1;
