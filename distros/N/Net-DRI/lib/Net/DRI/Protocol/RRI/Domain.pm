## Domain Registry Interface, RRI Domain commands (DENIC-11)
##
## Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::RRI::Domain;

use strict;

##use IDNA::Punycode;
use DateTime::Format::ISO8601 ();

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::ContactSet;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRI::Domain - RRI Domain commands (DENIC-11) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           transfer_query  => [ \&transfer_query, \&transfer_parse ],
           create => [ \&create, \&create_parse ],
           delete => [ \&delete ],
           transfer_request => [ \&transfer_request ],
           transfer_answer  => [ \&transfer_answer ],
           trade => [ \&trade ],
           update => [ \&update],
         );

 ##$tmp{check_multi} = $tmp{check};
 return { 'domain' => \%tmp };
}

sub build_command
{
 my ($msg, $command, $domain, $domainattr, $dns) = @_;
 my @dom = (ref($domain))? @$domain : ($domain);
 Net::DRI::Exception->die(1,'protocol/RRI', 2, 'Domain name needed')
	unless @dom;
 foreach my $d (@dom)
 {
  Net::DRI::Exception->die(1, 'protocol/RRI', 2, 'Domain name needed')
	unless defined($d) && $d;
  Net::DRI::Exception->die(1, 'protocol/RRI', 10, 'Invalid domain name: ' . $d)
	unless Net::DRI::Util::is_hostname($d);
 }

 my $tcommand = (ref($command)) ? $command->[0] : $command;
 my @ns = @{$msg->ns->{domain}};
 $msg->command(['domain', $tcommand, (defined($dns) ? $dns : $ns[0]), $domainattr]);

 my @d;

 foreach my $domain (@dom)
 {
  ##my $ace = join('.', map { decode_punycode($_) } split(/\./, $domain));
  push @d, ['domain:handle', $domain];
  push @d, ['domain:ace', $domain];
 }
 return @d;
}

####################################################################################################
########### Query commands

sub check
{
 my ($rri, $domain, $rd)=@_;
 my $mes = $rri->message();
 my @d = build_command($mes, 'check', $domain);
 $mes->command_body(\@d);
 $mes->cltrid(undef);
}


sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $chkdata = $mes->get_content('checkData',$mes->ns('domain'));
 return unless $chkdata;
 my @d = $chkdata->getElementsByTagNameNS($mes->ns('domain'),'handle');
 my @s = $chkdata->getElementsByTagNameNS($mes->ns('domain'),'status');
 return unless (@d && @s);

 my $dom = $d[0]->getFirstChild()->getData();
 $rinfo->{domain}->{$dom}->{action} = 'check';
 $rinfo->{domain}->{$dom}->{exist} =  ($s[0]->getFirstChild()->getData() eq 'free')? 0 : 1;
}

sub info
{
 my ($rri, $domain, $rd)=@_;
 my $mes = $rri->message();
 my @d = build_command($mes, 'info', $domain,
	{recursive => 'false', withProvider => 'true'});
 $mes->command_body(\@d);
 $mes->cltrid(undef);
}

sub info_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();
 my $infdata = $mes->get_content('infoData', $mes->ns('domain'));
 return unless $infdata;
 my $cs = Net::DRI::Data::ContactSet->new();
 my $ns = Net::DRI::Data::Hosts->new();
 my $c = $infdata->getFirstChild();

 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name = $c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'handle')
  {
   $oname = lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action} = 'info';
   $rinfo->{domain}->{$oname}->{exist} = 1;
  }
  elsif ($name eq 'status')
  {
   my $val = $c->getFirstChild()->getData();
   $rinfo->{domain}->{$oname}->{exist} = ($val eq 'connect')? 1 : 0;
  }
  elsif ($name eq 'contact')
  {
   my $role = $c->getAttribute('role');
   my %rmap = ('holder' => 'registrant', 'admin-c' => 'admin',
	'tech-c' => 'tech', 'zone-c' => 'zone');
   my @hndl_tags = $c->getElementsByTagNameNS($mes->ns('contact'),'handle');
   my $hndl_tag = $hndl_tags[0];
   $role = $rmap{$role} if (defined($rmap{$role}));
   $cs->add($po->create_local_object('contact')->srid($hndl_tag->getFirstChild()->getData()), $role)
	if (defined($hndl_tag));
  }
  elsif ($name eq 'dnsentry')
  {
   $ns->add(parse_ns($mes,$c));
  }
  elsif ($name eq 'regAccId')
  {
   $rinfo->{domain}->{$oname}->{clID} =
   $rinfo->{domain}->{$oname}->{crID} =
   $rinfo->{domain}->{$oname}->{upID} = $c->getFirstChild()->getData();
  }
  elsif ($name eq 'changed')
  {
   $rinfo->{domain}->{$oname}->{crDate} =
   $rinfo->{domain}->{$oname}->{upDate} =
	DateTime::Format::ISO8601->new()->
		parse_datetime($c->getFirstChild()->getData());
  }
  elsif ($name eq 'chprovData')
  {
   # FIXME: Implement this one as well
  }
 } continue { $c = $c->getNextSibling(); }

 $rinfo->{domain}->{$oname}->{contact} = $cs;
 $rinfo->{domain}->{$oname}->{status} = $po->create_local_object('status');
 $rinfo->{domain}->{$oname}->{ns} = $ns;
}

sub parse_ns
{
 my $mes = shift;
 my $node = shift;
 my $n = $node->getFirstChild();
 my $hostname = '';
 my @ip4 = ();
 my @ip6 = ();

 while ($n)
 {
  next unless ($n->nodeType() == 1); ## only for element nodes
  my $name = $n->localname() || $n->nodeName();
  next unless $name;

  if ($name eq 'rdata')
  {
   my $nn = $n->getFirstChild();
   while ($nn)
   {
    next unless ($nn->nodeType() == 1); ## only for element nodes
    my $name2 = $nn->localname() || $nn->nodeName();
    next unless $name2;
    if ($name2 eq 'nameserver')
    {
     $hostname = $nn->getFirstChild()->getData();
     $hostname =~ s/\.$// if ($hostname =~ /\.$/);
    }
    elsif ($name2 eq 'address')
    {
     my $ip = $nn->getFirstChild()->getData();
     if ($ip=~m/:/)
     {
      push @ip6, $ip;
     }
     else
     {
      push @ip4, $ip;
     }
    }
   } continue { $nn = $nn->getNextSibling(); }
  }
 } continue { $n = $n->getNextSibling(); }

 return ($hostname, \@ip4, \@ip6);
}

sub transfer_query
{
 my ($rri, $domain, $rd)=@_;
 my $mes = $rri->message();
 my @d = build_command($mes, 'info', $domain,
	{recursive => 'true', withProvider => 'false'});
 $mes->command_body(\@d);
}

sub transfer_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $infodata = $mes->get_content('infoData', $mes->ns('domain'));
 return unless $infodata;
 my $namedata = ($infodata->getElementsByTagNameNS($mes->ns('domain'),
	'handle'))[0];
 return unless $namedata;
 my $trndata = ($infodata->getElementsByTagNameNS($mes->ns('domain'),
	'chprovData'))[0];
 return unless $trndata;

 $oname = lc($namedata->getFirstChild()->getData());
 $rinfo->{domain}->{$oname}->{action} = 'transfer';
 $rinfo->{domain}->{$oname}->{exist} = 1;
 $rinfo->{domain}->{$oname}->{trStatus} = undef;

 my $c = $trndata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name = $c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'chprovTo')
  {
   $rinfo->{domain}->{$oname}->{reID} = $c->getFirstChild()->getData();
  }
  elsif ($name eq 'chprovStatus')
  {
   my %stmap = (ACTIVE => 'pending', REMINDED => 'pending');
   my $val = $c->getFirstChild()->getData();
   $rinfo->{domain}->{$oname}->{trStatus} =
	(defined($stmap{$val}) ? $stmap{$val} : $val);
  }
  elsif ($name =~ m/^(chprovStart|chprovReminder|chprovEnd)$/)
  {
   my %tmmap = (chprovStart => 'reDate', chprovReminder => 'acDate',
	chprovEnd => 'exDate');
   $rinfo->{domain}->{$oname}->{$tmmap{$1}} = DateTime::Format::ISO8601->
	new()->parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c = $c->getNextSibling(); }
}

############ Transform commands

sub create
{
 my ($rri, $domain, $rd) = @_;
 my $mes = $rri->message();
 my %ns = map { $_ => $mes->ns->{$_}->[0] } qw(domain dnsentry xsi);
 my @d = build_command($mes, 'create', $domain, undef, \%ns);
 
 my $def = $rri->default_parameters();
 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) &&
	(ref($def->{domain_create}) eq 'HASH'))
 {
  $rd = {} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  while (my ($k, $v) = each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k} = $v;
  }
 }

 ## Contacts, all OPTIONAL
 push @d,build_contact($rd->{contact}) if Net::DRI::Util::has_contact($rd);

 ## Nameservers, OPTIONAL
 push @d,build_ns($rri,$rd->{ns},$domain) if Net::DRI::Util::has_ns($rd);

 $mes->command_body(\@d);
}

sub build_contact
{
 my $cs = shift;
 my @d;

 my %trans = ('registrant' => 'holder', 'admin' => 'admin-c',
	'tech' => 'tech-c', 'zone' => 'zone-c');

 # All nonstandard contacts go into the extension section
 foreach my $t (sort($cs->types()))
 {
  my @o = $cs->get($t);
  my $c = (defined($trans{$t}) ? $trans{$t} : $t);
  push @d, map { ['domain:contact', $_->srid(), {'role' => $c}] } @o;
 }
 return @d;
}

sub build_ns
{
 my ($rri,$ns,$domain,$xmlns)=@_;
 my @d;

 foreach my $i (1..$ns->count())
 {
  my ($n, $v4, $v6) = $ns->get_details($i);
  my @h = map { ['dnsentry:address', $_] } (@{$v4}, @{$v6});
  push @d, ['dnsentry:dnsentry', {'xsi:type' => 'dnsentry:NS'},
	['dnsentry:owner', $domain . '.'],
	['dnsentry:rdata', ['dnsentry:nameserver', $n . '.' ], @h ] ];
 }

 $xmlns='dnsentry' unless defined($xmlns);
 return @d;
}

sub create_parse
{
 my ($po, $otype, $oaction, $oname, $rinfo) = @_;
 my $mes = $po->message();
 return unless $mes->is_success();

 my $credata = $mes->get_content('creData', $mes->ns('domain'));
 return unless $credata;

 my $c = $credata->getFirstChild();
 while ($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name = $c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname = lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action} = 'create';
   $rinfo->{domain}->{$oname}->{exist} = 1;
  }
  elsif ($name =~ m/^(crDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1} = DateTime::Format::ISO8601->new()->
	parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c = $c->getNextSibling(); }
}

sub delete
{
 my ($rri, $domain, $rd) = @_;
 my $mes = $rri->message();
 my @d = build_command($mes, 'delete', $domain);

 ## Holder contact
 if (Net::DRI::Util::has_contact($rd))
 {
  my $ocs = $rd->{contact};
  my $cs = Net::DRI::Data::ContactSet->new();
  foreach my $c ($ocs->get('registrant'))
  {
   $cs->add($c, 'registrant');
  }

  push @d, build_contact($cs);
 }

 $mes->command_body(\@d);
}

sub transfer_request
{
 my ($rri, $domain, $rd) = @_;
 my $mes = $rri->message();
 my %ns = map { $_ => $mes->ns->{$_}->[0] } qw(domain dnsentry xsi);
 my @d = build_command($mes, 'chprov', $domain, undef, \%ns);

 ## Contacts, all OPTIONAL
 push @d,build_contact($rd->{contact}) if Net::DRI::Util::has_contact($rd);

 ## Nameservers, OPTIONAL
 push @d, build_ns($rri, $rd->{ns}, $domain) if Net::DRI::Util::has_ns($rd);

 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($rri, $domain, $rd) = @_;
 my $mes = $rri->message();
 my @d = build_command($mes, (Net::DRI::Util::has_key($rd,'approve') && $rd->{approve}) ?
	'chprovAck' : 'chprovNack', $domain);
 $mes->command_body(\@d);
}

sub trade
{
 my ($rri, $domain, $rd) = @_;
 my $mes = $rri->message();
 my %ns = map { $_ => $mes->ns->{$_}->[0] } qw(domain dnsentry xsi);
 my @d = build_command($mes, 'chholder', $domain, undef, \%ns);
 
 my $def = $rri->default_parameters();
 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) &&
	(ref($def->{domain_create}) eq 'HASH'))
 {
  $rd = {} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  while (my ($k, $v) = each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k} = $v;
  }
 }

 ## Contacts, all OPTIONAL
 push @d,build_contact($rd->{contact}) if Net::DRI::Util::has_contact($rd);

 ## Nameservers, OPTIONAL
 push @d, build_ns($rri, $rd->{ns}, $domain) if Net::DRI::Util::has_ns($rd);

 $mes->command_body(\@d);
}

sub update
{
 my ($rri, $domain, $todo, $rd)=@_;
 my $mes = $rri->message();
 my %ns = map { $_ => $mes->ns->{$_}->[0] } qw(domain dnsentry xsi);
 my $ns = $rd->{ns};
 my $cs = $rd->{contact};

 Net::DRI::Exception::usererr_invalid_parameters($todo.' must be a Net::DRI::Data::Changes object') unless Net::DRI::Util::isa_changes($todo);

 Net::DRI::Exception::usererr_invalid_parameters('Must specify contact set and name servers with update command (or use the proper API)') unless (Net::DRI::Util::isa_contactset($cs) && Net::DRI::Util::isa_hosts($ns));

 if ((grep { ! /^(?:add|del)$/ } $todo->types('ns')) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('contact')))
 {
  Net::DRI::Exception->die(0, 'protocol/RRI', 11, 'Only ns/status/contact add/del or registrant/authinfo set available for domain');
 }

 my @d = build_command($mes, 'update', $domain, undef, \%ns);

 my $nsadd = $todo->add('ns');
 my $nsdel = $todo->del('ns');
 my $cadd = $todo->add('contact');
 my $cdel = $todo->del('contact');

 if (defined($nsadd)) { foreach my $hostname ($nsadd->get_names())
 {
   $ns->add($nsadd->get_details($hostname));
 } }

 if (defined($nsdel))
 {
  my $newns =Net::DRI::Data::Hosts->new();

  foreach my $hostname ($ns->get_names())
  {
   if (!grep { $_ eq $hostname } $nsdel->get_names())
   {
    $newns->add($ns->get_details($hostname));
   }
  }

  $ns = $newns;
 }

 if (defined($cadd)) { foreach my $type ($cadd->types()) {
  foreach my $c ($cadd->get($type))
  {
   $cs->add($c, $type);
  }
 } }

 if (defined($cdel)) { foreach my $type ($cdel->types()) {
  foreach my $c ($cdel->get($type))
  {
   $cs->del($c, $type);
  }
 } }

 push @d, build_contact($cs);
 push @d, build_ns($rri, $ns, $domain);

 $mes->command_body(\@d);
}

####################################################################################################
1;
