## Domain Registry Interface, .PL Contact EPP extension commands
##
## Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::PL::Contact;

use strict;

use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Contact - .PL EPP Contact extension commands for Net::DRI

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

Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>.
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
          create => [ \&create, undef ],
          info   => [ \&info, undef ],
          update => [ \&update, undef ],
         );

 return { 'contact' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:extcon="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('pl_contact')));
}

sub add_individual_and_consent
{
 my ($epp,$contact,$op)=@_;
 my $mes=$epp->message();

 ## validate() has already been called
 my $ind=$contact->individual();
 my $cfp=$contact->consent_for_publishing();

 return unless (defined($ind) || defined($cfp));
 my $eid=build_command_extension($mes,$epp,'extcon:'.$op);
 my @e;
 push @e,['extcon:individual',$ind]           if defined($ind);
 push @e,['extcon:consentForPublishing',$cfp] if defined($cfp);

 $mes->command_extension($eid,\@e);
}

sub create 
{
 my ($epp,$contact)=@_;
 return add_individual_and_consent($epp,$contact,'create'); 
}

sub update 
{
 my ($epp,$contact,$todo)=@_;
 my $newc=$todo->set('info');
 return unless $newc;
 return add_individual_and_consent($epp,$newc,'update');
}

sub info
{
 my ($epp,$contact,$ep)=@_;
 my $mes=$epp->message();

 return unless (Net::DRI::Util::has_auth($ep) && exists($ep->{auth}->{pw}));

 my $eid=build_command_extension($mes,$epp,'extcon:info');
 $mes->command_extension($eid,[['extcon:authInfo',['extcon:pw',$ep->{auth}->{pw}]]]);
}

####################################################################################################
1;
