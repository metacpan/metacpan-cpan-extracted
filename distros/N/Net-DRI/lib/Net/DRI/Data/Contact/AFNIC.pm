## Domain Registry Interface, Handling of contact data for AFNIC
##
## Copyright (c) 2006,2008,2009,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
#########################################################################################

package Net::DRI::Data::Contact::AFNIC;

use strict;
use warnings;

use base qw/Net::DRI::Data::Contact/;

use Email::Valid;

use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->register_attributes(qw(firstname legal_form legal_form_other legal_id jo trademark key birth vat id_status));

=pod

=head1 NAME

Net::DRI::Data::Contact::AFNIC - Handle AFNIC contact data for Net::DRI

=head1 DESCRIPTION

This subclass of Net::DRI::Data::Contact adds accessors and validation for
AFNIC specific data.

=head1 METHODS

The following accessors/mutators can be called in chain, as they all return the object itself.

=head2 firstname()

Please note that for AFNIC data, the name() must be only the lastname, hence this extra firstname() method needed for contacts being individuals

=head2 legal_form()

for an organization, either 'A' or 'association' for non profit organization, 'S' or 'company' for company or 'other' for other types;
this must be set for contacts being moral entities

=head2 legal_form_other()

type of organization for other types

=head2 legal_id()

French SIREN/SIRET of organization

=head2 jo()

reference to an hash with 4 keys storing details about «Journal Officiel» :
date_declaration (Declaration date), date_publication (Publication date),
number (Announce number) and page (Announce page)

a waldec key can also be present for the waldec id

=head2 trademark()

for trademarks, its number

=head2 vat()

vat number (not used by registry for now)

=head2 key()

registrant invariant key

=head2 birth()

reference to an hash with 2 keys storing details about birth of contact :
date (Date of birth) and place (Place of birth)

=head2 id_status()

set by registry, the current identication status of the contact

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006,2008,2009,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

our $LETTRES=qr(A-Z\x{C0}\x{C2}\x{C7}\x{C8}\x{C9}\x{CA}\x{CB}\x{CE}\x{CF}\x{D4}\x{D9}\x{DB}\x{DC}\x{178}\x{C6}\x{152}a-z\x{E0}\x{E2}\x{E7}\x{E8}\x{E9}\x{EA}\x{EB}\x{EE}\x{EF}\x{F4}\x{F9}\x{FB}\x{FC}\x{FF}\x{E6}\x{153});
our $NOM_LIBRE_ITEM=qr{[${LETTRES}0-9\(\)\.\[\]\?\+\*#&/!\@',><":-]+};
our $NOM_PROPRE_ITEM=qr{[${LETTRES}]+(('?(?:[${LETTRES}]+(?:\-?[${LETTRES}]+)?)+)|(?:\.?))};
our $NOM_PROPRE=qr{${NOM_PROPRE_ITEM}( +${NOM_PROPRE_ITEM})*};
our $ADRESSE_ITEM=qr{[${LETTRES}0-9\(\)\./',"#-]+};
our $NOM_COMMUNE_ITEM=qr{[${LETTRES}]+(?:['-]?[${LETTRES}]+)*};

sub is_nom_libre { return shift=~m/^(?:${NOM_LIBRE_ITEM} *)*[${LETTRES}0-9]+(?: *${NOM_LIBRE_ITEM}*)*$/; }
sub is_adresse   { return shift=~m/^(?:${ADRESSE_ITEM} *)*[${LETTRES}]+(?: *${ADRESSE_ITEM})*$/; }
sub is_commune   { return shift=~m/^${NOM_COMMUNE_ITEM}(?:(?:(?: *\/ *)|(?: +))${NOM_COMMUNE_ITEM})*(?: +(?:[cC][eE][dD][eE][xX]|[cC][dD][xX])(?: +[0-9]+)?)?$/; }
sub is_code_fr   { return shift=~m/^(?:FR|RE|MQ|GP|GF|TF|NC|PF|WF|PM|YT)$/; }
sub is_dep_fr    { return shift=~m/^(?:0[1-9])|(?:[1345678][0-9])|(?:2[1-9ABab])|(?:9[0-5])|(?:97[1-5])|(?:98[5-8])$/; }

sub validate
{
 my ($self,$change)=@_;
 $change||=0;

 $self->SUPER::validate(1); ## will trigger an Exception if problem

 my @errs;
 push @errs,'srid' if ($self->srid() && $self->srid()!~m/^[A-Z]+(?:[1-9][0-9]*)?(?:-FRNIC)?$/i);
 push @errs,'name' if ($self->name() && ($self->name()!~m/^${NOM_PROPRE}$/ || ! is_nom_libre($self->name())));
 push @errs,'firstname' if ($self->firstname() && $self->firstname()!~m/^${NOM_PROPRE}$/);
 push @errs,'org'  if ($self->org()  && ! is_nom_libre($self->org()));

 push @errs,'legal_form'       if ($self->legal_form()       && $self->legal_form()!~m/^(?:A|S|company|association|other)$/); ## AS for email, the rest for EPP
 push @errs,'legal_form_other' if ($self->legal_form_other() && ! is_nom_libre($self->legal_form_other()));
 push @errs,'legal_id'         if ($self->legal_id()         && $self->legal_id()!~m/^[0-9]{9}(?:[0-9]{5})?$/);

 my $jo=$self->jo();
 if ($jo)
 {
  if ((ref($jo) eq 'HASH') && exists($jo->{date_declaration}) && exists($jo->{date_publication}) && exists($jo->{number}) && exists ($jo->{page}))
  {
   push @errs,'jo' unless ($jo->{date_declaration}=~m!^[0-9]{2}/[0-9]{2}/[0-9]{4}$! || $jo->{date_declaration}=~m!^[0-9]{4}-[0-9]{2}-[0-9]{2}$!);
   push @errs,'jo' unless ($jo->{date_publication}=~m!^[0-9]{2}/[0-9]{2}/[0-9]{4}$! || $jo->{date_publication}=~m!^[0-9]{4}-[0-9]{2}-[0-9]{2}$!);
   push @errs,'jo' unless $jo->{number}=~m/^[1-9][0-9]*$/;
   push @errs,'jo' unless $jo->{page}=~m/^[1-9][0-9]*$/;
  } else
  {
   push @errs,'jo';
  }
 }

 push @errs,'vat'       if ($self->vat()       && !Net::DRI::Util::xml_is_token($self->vat()));
 push @errs,'trademark' if ($self->trademark() && $self->trademark()!~m/^[0-9]*[A-Za-z]*[0-9]+$/);

 push @errs,'key' if ($self->key() && $self->key()!~m/^[A-Za-z]{8}-[1-9][0-9]{2}$/);

 my $birth=$self->birth();
 if ($birth)
 {
  if ((ref($birth) eq 'HASH') && exists($birth->{date}) && exists($birth->{place}))
  {
   push @errs,'birth' unless ((ref($birth->{date}) eq 'DateTime') || $birth->{date}=~m!^[0-9]{4}-[0-9]{2}-[0-9]{2}$! || $birth->{date}=~m!^[0-9]{2}/[0-9]{2}/[0-9]{4}$!);
   push @errs,'birth' unless (($birth->{place}=~m/^[A-Za-z]{2}$/ && ! is_code_fr($birth->{place})) || ($birth->{place}=~m/^(?:[0-9]{5}|) *, *(.+)$/ && is_commune($1)));
  } else
  {
   push @errs,'birth';
  }
 }

 my $isccfr=$self->cc()? is_code_fr(uc($self->cc())) : 0;

 ## Not same checks as AFNIC, but we will translate to their format when needed, better to standardize on EPP
 if ($self->voice())
 {
  push @errs,'voice' if $self->voice()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/;
  push @errs,'voice' if ($isccfr && $self->voice()!~m/^\+33\./);
 }
 if ($self->fax())
 {
  push @errs,'fax' if $self->fax()!~m/^\+[0-9]{1,3}\.[0-9]{1,14}(?:x\d+)?$/;
  push @errs,'fax' if ($isccfr && $self->fax()!~m/^\+33\./);
 }
 push @errs,'email' if ($self->email() && !Email::Valid->rfc822($self->email()));

 ## Maintainer is not tied to contact

 push @errs,'disclose' if ($self->disclose() && $self->disclose()!~m/^[ONY]$/i);

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

sub validate_registrant
{
 my $self=shift;
 my @errs;
 my $rs=$self->street();
 push @errs,'street' if ($rs && ((ref($rs) ne 'ARRAY') || (@$rs > 3) || (grep { ! is_adresse($_) } @$rs)));
 push @errs,'city' if ($self->city() && ! is_commune($self->city()));

 my $cc=$self->cc();
 my $isccfr=0;
 if ($cc)
 {
  push @errs,'cc' if !exists($Net::DRI::Util::CCA2{uc($cc)});
  $isccfr=is_code_fr(uc($cc));
 }

 my $pc=$self->pc();
 if ($pc)
 {
  if ($isccfr)
  {
   push @errs,'pc' unless $pc=~m/^[0-9]{5}$/;
  } else
  {
   push @errs,'pc' unless $pc=~m/^[-0-9A-Za-z ]+$/;
  }
 }

 Net::DRI::Exception::usererr_invalid_parameters('Invalid contact information: '.join('/',@errs)) if @errs;
 return 1; ## everything ok.
}

sub init
{
 my ($self,$what,$ndr)=@_;
 my $pn=$ndr->protocol()->name();
 if ($what eq 'create' && $pn eq 'EPP')
 {
  $self->srid('AUTO') unless defined($self->srid()); ## we can not choose the ID
 }
}

####################################################################################################
1;
