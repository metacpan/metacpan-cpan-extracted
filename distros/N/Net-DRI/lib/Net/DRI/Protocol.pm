## Domain Registry Interface, Protocol superclass
##
## Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol;

use strict;
use warnings;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_accessors(qw(name version commands message default_parameters));

use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;

use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Changes;
use Net::DRI::Data::Contact;
use Net::DRI::Data::ContactSet;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::StatusList;

our $VERSION=do { my @r=(q$Revision: 1.22 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol - Superclass of all Net::DRI Protocols

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my ($c)=@_;

 my $self={	capabilities => {},
		factories => { 	datetime	=> sub { return DateTime->new(@_); },
				duration	=> sub { return DateTime::Duration->new(@_); },
				changes  	=> sub { return Net::DRI::Data::Changes->new(@_); },
				contact  	=> sub { return Net::DRI::Data::Contact->new(); },
				contactset 	=> sub { return Net::DRI::Data::ContactSet->new(@_); },
				hosts		=> sub { return Net::DRI::Data::Hosts->new(@_); },
				status		=> sub { return Net::DRI::Data::StatusList->new(@_); },
				},
	};

 bless($self,$c);

 $self->message(undef);
 $self->default_parameters({});
 return $self;
}

sub parse_iso8601
{
 my ($self,$d)=@_;
 $self->{iso8601_parser}=DateTime::Format::ISO8601->new() unless exists $self->{iso8601_parser};
 return $self->{iso8601_parser}->parse_datetime($d);
}

sub build_strptime_parser
{
 my $self=shift;
 my $key=join('|',@_);
 $self->{strptime_parser}->{$key}=DateTime::Format::Strptime->new(@_) unless exists $self->{strptime_parser}->{$key};
 return $self->{strptime_parser}->{$key};
}

sub create_local_object
{
 my $self=shift;
 my $what=shift;
 return unless defined $self && defined $what;
 my $fn=$self->factories();
 return unless (defined($fn) && ref($fn) && exists($fn->{$what}) && (ref($fn->{$what}) eq 'CODE'));
 return $fn->{$what}->(@_);
}

## This should not be called multiple times for a given Protocol class (as it will erase the loaded_modules slot)
sub _load
{
 my $self=shift;
 my $etype='protocol/'.$self->name();
 my $version=$self->version();

 my (%c,%done,@done);
 foreach my $class (@_)
 {
  next if exists($done{$class});
  $class->require or Net::DRI::Exception::err_failed_load_module($etype,$class,$@);
  Net::DRI::Exception::err_method_not_implemented('register_commands() in '.$class) unless $class->can('register_commands');
  my $rh=$class->register_commands($version);
  Net::DRI::Util::hash_merge(\%c,$rh); ## { object type => { action type => [ build action, parse action ]+ } }
  if ($class->can('capabilities_add'))
  {
   my @a=$class->capabilities_add();
   if (ref($a[0]))
   {
    foreach my $a (@a) { $self->capabilities(@$a); }
   } else
   {
    $self->capabilities(@a);
   }
  }
  $done{$class}=1;
  push @done,$class;
 }

 $self->{loaded_modules}=\@done;
 $self->commands(\%c);
 return;
}

sub has_module
{
 my ($self,$mod)=@_;
 return 0 unless defined $mod && $mod;
 return (grep { $_ eq $mod } @{$self->{loaded_modules}})? 1 : 0;
}

sub _load_commands
{
 my ($self,$otype,$oaction)=@_;

 my $etype='protocol/'.$self->name();
 Net::DRI::Exception->die(1,$etype,7,'Object type and/or action not defined') unless (defined($otype) && $otype && defined($oaction) && $oaction);
 my $h=$self->commands();
 Net::DRI::Exception->die(1,$etype,8,'No actions defined for object of type <'.$otype.'>') unless exists($h->{$otype});
 Net::DRI::Exception->die(1,$etype,9,'No action name <'.$oaction.'> defined for object of type <'.$otype.'> in '.ref($self)) unless exists($h->{$otype}->{$oaction});
 return $h;
}

sub has_action
{
 my ($self,$otype,$oaction)=@_;
 eval {
  my $h=$self->_load_commands($otype,$oaction);
 };

 return ($@)? 0 : 1;
}

sub action
{
 my $self=shift;
 my $otype=shift;
 my $oaction=shift;
 my $trid=shift;
 my $h=$self->_load_commands($otype,$oaction);

 ## Create a new message from scratch and loop through all functions registered for given action & type
 my $msg=$self->create_local_object('message',$trid,$otype,$oaction);
 Net::DRI::Exception->die(0,'protocol',1,'Unsuccessfull message creation') unless ($msg && ref($msg) && $msg->isa('Net::DRI::Protocol::Message'));
 $self->message($msg); ## store it for later use (in loop below)

 foreach my $t (@{$h->{$otype}->{$oaction}})
 {
  my $pf=$t->[0];
  next unless (defined($pf) && (ref($pf) eq 'CODE'));
  $pf->($self,@_);
 }

 $self->message(undef); ## needed ? useful ?
 return $msg;
}

sub reaction
{
 my ($self,$otype,$oaction,$dr,$sent,$oname)=@_;
 my $h=$self->_load_commands($otype,$oaction);
 my $msg=$self->create_local_object('message');
 Net::DRI::Exception->die(0,'protocol',1,'Unsuccessfull message creation') unless ($msg && ref($msg) && $msg->isa('Net::DRI::Protocol::Message'));

 my %info;
 ## TODO is $sent needed here really ? if not remove from API above also !
 $msg->parse($dr,\%info,$otype,$oaction,$sent); ## will trigger an Exception by itself if problem ## TODO : add  later the whole LocalStorage stuff done when sending ? (instead of otype/oaction/message sent)
 $self->message($msg); ## store it for later use (in loop below)
 $info{$otype}->{$oname}->{name}=$oname if ($otype eq 'domain' || $otype eq 'host');

 foreach my $t (@{$h->{$otype}->{$oaction}})
 {
  my $pf=$t->[1];
  next unless (defined($pf) && (ref($pf) eq 'CODE'));
  $pf->($self,$otype,$oaction,$oname,\%info);
 }

 my $rc=$msg->result_status();
 if (defined($rc))
 {
  foreach my $v1 (values(%info))
  {
   next unless (ref($v1) eq 'HASH' && keys(%$v1));
   foreach my $v2 (values(%{$v1}))
   {
    next unless (ref($v2) eq 'HASH' && keys(%$v2)); ## yes, this can happen, with must_reconnect for example
    next if exists($v2->{result_status});
    $v2->{result_status}=$rc;
   }
  }
 }
 $self->message(undef); ## needed ? useful ?

 return ($rc,\%info);
}

sub nameversion
{
 my $self=shift;
 return $self->name().'/'.$self->version();
}

sub factories
{
 my ($self,$object,$code)=@_;
 if (defined $object && defined $code)
 {
  $self->{factories}->{$object}=$code;
  return $self;
 }
 return $self->{factories};
}

sub capabilities
{
 my ($self,$action,$object,$cap)=@_;
 if (defined($action) && defined($object))
 {
  $self->{capabilities}->{$action}={} unless exists($self->{capabilities}->{$action});
  if (defined($cap))
  {
   $self->{capabilities}->{$action}->{$object}=$cap;
  } else
  {
   delete($self->{capabilities}->{$action}->{$object});
  }
 }
 return $self->{capabilities};
}

####################################################################################################
1;
