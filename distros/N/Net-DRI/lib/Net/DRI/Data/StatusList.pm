## Domain Registry Interface, Handling of statuses list (order is irrelevant) (base class)
##
## Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Data::StatusList;

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Data::StatusList - Handle a collection of statuses for an object, in a registry independent fashion for Net::DRI

=head1 DESCRIPTION

You should never have to use this class directly, but you may get back objects that
are instances of subclasses of this class. An object of this class can store the statuses' names,
with a message for each and a language tag, and any other stuff, depending on registry.

=head1 METHODS

=head2 is_active()

returns 1 if these statuses enable an object to be active

=head2 is_published()

returns 1 if these statuses enable the object to be published on registry DNS servers

=head2 is_pending()

returns 1 if these statuses are for an object that is pending some action at registry

=head2 is_linked()

returns 1 if these statuses are for an object that is linked to another one at registry

=head2 can_update()

returns 1 if these statuses allow to update the object at registry

=head2 can_transfer()

returns 1 if these statuses allow to transfer the object at registry

=head2 can_delete()

returns 1 if these statuses allow to delete the object at registry

=head2 can_renew()

returns 1 if these statuses allow to renew the object at registry

=head2 possible_no()

returns an array with the list of available status to use in the no() call

=head2 no()

can be used to build a status, which will be added to the list. Must be given three parameters:
  a status (from list given by C<possible_no()>), a message (optional), a lang (optional, default to 'en')

=head1 INTERNAL METHODS

You may also use the following methods, but they should be less useful as
the purpose of the module is to give an abstract view of the underlying statuses.

=head2 list_status()

to get only the statuses' names, as an array of sorted names

=head2 status_details()

to get an hash ref with all status information

=head2 has_any()

returns 1 if the object has any of the statuses given as arguments

=head2 has_not()

returns 1 if the object has none of the statuses given as arguments

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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
 my $class=shift;
 my $pname=shift || '?';
 my $pversion=shift || '?';

 my $self={ proto_name    => $pname,
            proto_version => $pversion,
            sl => {}, ## statusname => { lang => lc(lang), msg => '', other per class }
          };

 bless($self,$class);
 $self->add(@_) if (@_);
 return $self;
}

sub _register_pno
{
 my ($self,$rs)=@_;
 $self->{possible_no}=$rs;
}

sub add
{
 my $self=shift;
 my $rs=$self->{sl};

 foreach my $el (@_)
 {
  if (ref($el))
  {
   my %tmp=%{$el};
   my $name=$tmp{name};
   delete($tmp{name});
   $rs->{$name}=\%tmp;
  } else
  {
   $rs->{$el}={};
  }
 }
 return $self;
}

sub rem
{
 my ($self,$status)=@_;
 my $rs=$self->{sl};
 delete($rs->{$status}) if exists($rs->{$status});
 return $self;
}

sub list_status
{
 my $self=shift;
 return sort(keys(%{$self->{sl}}));
}

sub status_details
{
 my $self=shift;
 return $self->{sl};
}

sub is_empty
{
 my $self=shift;
 my @a=$self->list_status();
 return (@a > 0)? 0 : 1;
}

sub has_any
{
 my $self=shift;
 my %tmp=map { uc($_) => 1 } $self->list_status();

 foreach my $el (@_)
 {
  return 1 if exists($tmp{uc($el)});
 }
 return 0;
}

sub has_not
{
 my $self=shift;
 my %tmp=map { uc($_) => 1 } $self->list_status();

 foreach my $el (@_)
 {
  return 0 if exists($tmp{uc($el)});
 }
 return 1;
}

sub possible_no
{
 my $self=shift;
 return sort(keys(%{$self->{possible_no}}));
}

sub no
{
 my ($self,$what,$msg,$lang)=@_;
 my $rs=$self->{possible_no};
 return $self unless (defined($what) && exists($rs->{$what}));
 if (defined($msg) && $msg)
 {
  $self->add({name=>$rs->{$what},msg=>$msg,lang=>(defined($lang) && $lang)? $lang : 'en'});
 } else
 {
  $self->add($rs->{$what});
 }
 return $self;
}

####################################################################################################
## Methods that must be defined in subclasses

sub is_active    { Net::DRI::Exception::err_method_not_implemented('is_active in '.ref($_[0])); }
sub is_published { Net::DRI::Exception::err_method_not_implemented('is_published in '.ref($_[0])); } 
sub is_pending   { Net::DRI::Exception::err_method_not_implemented('is_pending in '.ref($_[0])); }
sub is_linked    { Net::DRI::Exception::err_method_not_implemented('is_linked in '.ref($_[0])); }
sub can_update   { Net::DRI::Exception::err_method_not_implemented('can_update in '.ref($_[0])); }
sub can_transfer { Net::DRI::Exception::err_method_not_implemented('can_transfer in '.ref($_[0])); }
sub can_delete   { Net::DRI::Exception::err_method_not_implemented('can_delete in '.ref($_[0])); }
sub can_renew    { Net::DRI::Exception::err_method_not_implemented('can_renew in '.ref($_[0])); }

####################################################################################################
1;
