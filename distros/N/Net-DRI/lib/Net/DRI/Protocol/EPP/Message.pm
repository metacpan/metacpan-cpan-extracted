## Domain Registry Interface, EPP Message
##
## Copyright (c) 2005-2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Message;

use strict;
use warnings;

use DateTime::Format::ISO8601 ();
use DateTime ();
use XML::LibXML ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Protocol::EPP::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version command command_body cltrid svtrid msg_id node_resdata node_extension node_msg result_greeting));

our $VERSION=do { my @r=(q$Revision: 1.25 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Message - EPP Message for Net::DRI

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

Copyright (c) 2005-2010 Patrick Mevzek <netdri@dotandco.com>.
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
 my $proto=shift;
 my $class=ref($proto) || $proto;
 my $trid=shift;

 my $self={ results => [], ns => {} };
 bless($self,$class);

 $self->cltrid($trid) if (defined($trid) && $trid);
 return $self;
}

sub _get_result
{
 my ($self,$what,$pos)=@_;
 $pos=0 unless defined($pos);
 my $rh=$self->{results}->[$pos];
 return unless (defined($rh) && (ref($rh) eq 'HASH') && keys(%$rh)==4);
 return $rh->{$what};
}

## TODO : these are not very useful here, they should be done in ResultStatus
## (they are only used from t/241epp_message.t)
sub results            { return @{shift->{results}}; }
sub results_code       { return map { $_->{code} } shift->results(); }
sub results_message    { return map { $_->{message} } shift->results(); }
sub results_lang       { return map { $_->{lang} } shift->results(); }
sub results_extra_info { return map { $_->{extra_info} } shift->results(); }

sub result_code       { return shift->_get_result('code',@_); }
sub result_message    { return shift->_get_result('message',@_); }
sub result_lang       { return shift->_get_result('lang',@_); }
sub result_extra_info { return shift->_get_result('extra_info',@_); }

sub ns
{
 my ($self,$what)=@_;
 return $self->{ns} unless defined($what);

 if (ref($what) eq 'HASH')
 {
  $self->{ns}=$what;
  return $what;
 }
 return unless exists($self->{ns}->{$what});
 return $self->{ns}->{$what}->[0];
}

sub nsattrs
{
 my ($self,$what)=@_;
 return unless (defined($what) && exists($self->{ns}->{$what}));
 my @n=@{$self->{ns}->{$what}};
 return ($n[0],$n[0],$n[1]);
}

sub is_success { return _is_success(shift->result_code()); }
sub _is_success { return (shift=~m/^1/)? 1 : 0; } ## 1XXX is for success, 2XXX for failures

sub result_status
{
 my $self=shift;
 my $prev;

 foreach my $rs (reverse(@{$self->{results}}))
 {
  my $rso=Net::DRI::Protocol::ResultStatus->new('epp',$rs->{code},undef,_is_success($rs->{code}),$rs->{message},$rs->{lang},$rs->{extra_info});
  $rso->_set_trid([ $self->cltrid(),$self->svtrid() ]);
  $rso->_add_next($prev) if defined($prev);
  $prev=$rso;
 }
 return $prev;
}

sub command_extension_register
{
 my ($self,$ocmd,$ons)=@_;

 $self->{extension}=[] unless exists($self->{extension});
 my $eid=1+$#{$self->{extension}};
 $self->{extension}->[$eid]=[$ocmd,$ons,[]];
 return $eid;
}

sub command_extension
{
 my ($self,$eid,$rdata)=@_;

 if (defined($eid) && ($eid >= 0) && ($eid <= $#{$self->{extension}}) && defined($rdata) && (((ref($rdata) eq 'ARRAY') && @$rdata) || ($rdata ne '')))
 {
  $self->{extension}->[$eid]->[2]=(ref($rdata) eq 'ARRAY')? [ @{$self->{extension}->[$eid]->[2]}, @$rdata ] : $rdata;
 } else
 {
  return $self->{extension};
 }
}

sub as_string
{
 my ($self)=@_;
 my $ens=sprintf('xmlns="%s" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="%s %s"',$self->nsattrs('_main'));
 my @d;
 push @d,'<?xml version="1.0" encoding="UTF-8" standalone="no"?>';
 push @d,'<epp '.$ens.'>';
 my ($cmd,$ocmd,$ons);
 my $rc=$self->command();
 ($cmd,$ocmd,$ons)=@$rc if (defined($rc) && ref($rc));

 my $attr='';
 ($cmd,$attr)=($cmd->[0],' '.join(' ',map { $_.'="'.$cmd->[1]->{$_}.'"' } keys(%{$cmd->[1]}))) if (defined($cmd) && ref($cmd));

 if (defined($cmd))
 {
  push @d,'<command>' if ($cmd ne 'hello');
  my $body=$self->command_body();

  if (!defined $ocmd && !defined $body)
  {
   push @d,'<'.$cmd.$attr.'/>';
  } else
  {
   push @d,'<'.$cmd.$attr.'>';
   if (defined $body && length $body)
   {
    push @d,(defined $ocmd && length $ocmd)? ('<'.$ocmd.' '.$ons.'>',Net::DRI::Util::xml_write($body),'</'.$ocmd.'>') : Net::DRI::Util::xml_write($body);
   } else
   {
    push @d,'<'.$ocmd.' '.$ons.'/>';
   }
   push @d,'</'.$cmd.'>';
  }
 }

 ## OPTIONAL extension
 my $ext=$self->{extension};
 if (defined($ext) && (ref($ext) eq 'ARRAY') && @$ext)
 {
  push @d,'<extension>';
  foreach my $e (@$ext)
  {
   my ($ecmd,$ens,$rdata)=@$e;
   if ($ecmd && $ens)
   {
    push @d,'<'.$ecmd.' '.$ens.'>';
    push @d,ref($rdata)? Net::DRI::Util::xml_write($rdata) : Net::DRI::Util::xml_escape($rdata);
    push @d,'</'.$ecmd.'>';
   } else
   {
    push @d,Net::DRI::Util::xml_escape(@$rdata);
   }
  }
  push @d,'</extension>';
 }

 ## OPTIONAL clTRID
 my $cltrid=$self->cltrid();
 if (defined($cmd) && ($cmd ne 'hello'))
 {
  push @d,'<clTRID>'.$cltrid.'</clTRID>' if (defined($cltrid) && $cltrid && Net::DRI::Util::xml_is_token($cltrid,3,64));
  push @d,'</command>';
 }
 push @d,'</epp>';

 return join('',@d);
}

sub get_response  { my $self=shift; return $self->_get_content($self->node_resdata(),@_); }
sub get_extension { my $self=shift; return $self->_get_content($self->node_extension(),@_); }

sub _get_content
{
 my ($self,$node,$nstag,$nodename)=@_;
 return unless (defined($node) && defined($nstag) && $nstag && defined($nodename) && $nodename);
 my $ns=$self->ns($nstag);
 $ns=$nstag unless defined($ns) && $ns;
 my @tmp=$node->getChildrenByTagNameNS($ns,$nodename);
 return unless @tmp;
 return $tmp[0];
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;

 my $NS=$self->ns('_main');
 my $parser=XML::LibXML->new();
 my $doc=$parser->parse_string($dc->as_string());
 my $root=$doc->getDocumentElement();
 Net::DRI::Exception->die(0,'protocol/EPP',1,'Unsuccessfull parse, root element is not epp') unless ($root->getName() eq 'epp');

 if (my $g=$root->getChildrenByTagNameNS($NS,'greeting'))
 {
  push @{$self->{results}},{ code => 1000, message => undef, lang => undef, extra_info => []}; ## fake an OK
  $self->result_greeting($self->parse_greeting($g->get_node(1)));
  return;
 }
 my $c=$root->getChildrenByTagNameNS($NS,'response');
 Net::DRI::Exception->die(0,'protocol/EPP',1,'Unsuccessfull parse, no response block') unless ($c->size()==1);
 my $res=$c->get_node(1);

 ## result block(s)
 foreach my $result ($res->getChildrenByTagNameNS($NS,'result')) ## one element if success, multiple elements if failure RFC4930 §2.6
 {
  push @{$self->{results}},Net::DRI::Protocol::EPP::Util::parse_result($result,$NS);
 }

 $c=$res->getChildrenByTagNameNS($NS,'msgQ');
 $rinfo->{message}->{info}={ count => 0, checked_on => DateTime->now() };
 if ($c->size()) ## OPTIONAL
 {
  my $msgq=$c->get_node(1);
  my $id=$msgq->getAttribute('id'); ## id of the message that has just been retrieved and dequeued (RFC4930) OR id of *next* available message (RFC3730)
  $rinfo->{message}->{info}->{id}=$id;
  $rinfo->{message}->{info}->{count}=$msgq->getAttribute('count');
  if ($msgq->hasChildNodes()) ## We will have childs only as a result of a poll request
  {
   my %d=( id => $id );
   $self->msg_id($id);
   $d{qdate}=DateTime::Format::ISO8601->new()->parse_datetime(Net::DRI::Util::xml_child_content($msgq,$NS,'qDate'));
   my $msgc=$msgq->getChildrenByTagNameNS($NS,'msg')->get_node(1);
   $d{lang}=$msgc->getAttribute('lang') || 'en';

   if (grep { $_->nodeType() == 1 } $msgc->childNodes())
   {
    $d{content}=$msgc->toString();
    $self->node_msg($msgc);
   } else
   {
    $d{content}=$msgc->textContent();
   }
   $rinfo->{message}->{$id}=\%d;
  }
 }

 $c=$res->getChildrenByTagNameNS($NS,'resData');
 $self->node_resdata($c->get_node(1)) if ($c->size()); ## OPTIONAL
 $c=$res->getChildrenByTagNameNS($NS,'extension');
 $self->node_extension($c->get_node(1)) if ($c->size()); ## OPTIONAL

 ## trID
 my $trid=$res->getChildrenByTagNameNS($NS,'trID')->get_node(1); ## we search only for <trID> as direct child of <response>, hence getChildren and not getElements !
 my $tmp=Net::DRI::Util::xml_child_content($trid,$NS,'clTRID');
 $self->cltrid($tmp) if defined($tmp);
 $tmp=Net::DRI::Util::xml_child_content($trid,$NS,'svTRID');
 $self->svtrid($tmp) if defined($tmp);
}

sub add_to_extra_info
{
 my ($self,$data)=@_;
 push @{$self->{results}->[-1]->{extra_info}},$data;
}

## Move to Core/Session ?
sub parse_greeting
{
 my ($self,$g)=@_;
 my %tmp;

 foreach my $el (Net::DRI::Util::xml_list_children($g))
 {
  my ($n,$c)=@$el;
  if ($n=~m/^(svID|svDate)$/)
  {
   $tmp{$1}=$c->textContent();
  } elsif ($n eq 'svcMenu')
  {
   foreach my $sel (Net::DRI::Util::xml_list_children($c))
   {
    my ($nn,$cc)=@$sel;
    if ($nn=~m/^(version|lang)$/)
    {
     push @{$tmp{$1}},$cc->textContent();
    } elsif ($nn eq 'objURI')
    {
     push @{$tmp{svcs}},$cc->textContent();
    } elsif ($nn eq 'svcExtension')
    {
     push @{$tmp{svcext}},map { $_->textContent() } grep { $_->getName() eq 'extURI' } $cc->getChildNodes();
    }
   }
  } elsif ($n eq 'dcp')
  {
   $tmp{dcp}=$c->toString(); ## does someone really need this data ??
  }
 }
 return \%tmp;
}

####################################################################################################
1;
