## Domain Registry Interface, EPP Session commands (RFC4930)
##
## Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::Session;

use strict;
use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Session - EPP Session commands (RFC4930 obsoleting RFC3730) for Net::DRI

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

Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>.
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
           noop    => [ \&hello ],
           logout  => [ \&logout ],
           login   => [ \&login ],
           connect => [ \&hello, \&parse_greeting ],
         );

 return { 'session' => \%tmp };
}

sub hello ## should trigger a greeting from server, allowed at any time
{
 my ($epp)=@_;
 my $mes=$epp->message();
 $mes->command(['hello']);
}

sub parse_greeting
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 $po->server_greeting($mes->result_greeting());
}

sub logout
{
 my ($epp)=@_;
 my $mes=$epp->message();
 $mes->command(['logout']);
}

sub login
{
 my ($epp,$id,$pass,$newpass,$opts)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('login & password') unless (defined($id) && $id && defined($pass) && $pass);

 Net::DRI::Exception::usererr_invalid_parameters('login')    unless Net::DRI::Util::xml_is_token($id,3,16);
 Net::DRI::Exception::usererr_invalid_parameters('password') unless Net::DRI::Util::xml_is_token($pass,6,16);
 Net::DRI::Exception::usererr_invalid_parameters('new password') if ($newpass && !Net::DRI::Util::xml_is_token($newpass,6,16));

 my $mes=$epp->message();
 $mes->command(['login']);
 my @d;
 push @d,['clID',$id];
 push @d,['pw',$pass];
 push @d,['newPW',$newpass] if $newpass;

 my $rg=$epp->server_greeting();
 my @o;
 my $tmp=_opt($opts,$rg,'version');
 Net::DRI::Exception::usererr_insufficient_parameters('version') unless defined($tmp);
 $tmp=$tmp->[0] if ref($tmp);
 Net::DRI::Exception::usererr_invalid_parameters('version') unless ($tmp=~m/^[1-9]+\.[0-9]+$/);
 push @o,['version',$tmp];
 $tmp=_opt($opts,$rg,'lang');
 Net::DRI::Exception::usererr_insufficient_parameters('lang') unless defined($tmp);
 $tmp=$tmp->[0] if ref($tmp);
 Net::DRI::Exception::usererr_invalid_parameters('lang') unless ($tmp=~m/^[a-z]{1,8}(?:-[a-z0-9]{1,8})?$/i);
 push @o,['lang',$tmp];
 push @d,['options',@o];

 my @s;
 $tmp=_opt($opts,$rg,'svcs');
 push @s,map { ['objURI',$_] } @$tmp if (defined($tmp) && (ref($tmp) eq 'ARRAY'));
 $tmp=_opt($opts,$rg,'svcext');
 push @s,['svcExtension',map {['extURI',$_]} @$tmp] if (defined($tmp) && (ref($tmp) eq 'ARRAY'));
 push @d,['svcs',@s] if @s;

 $mes->command_body(\@d);
}

sub _opt
{
 my ($ro,$rg,$w)=@_;
 return $ro->{$w} if ($ro && (ref($ro) eq 'HASH') && exists($ro->{$w}));
 return $rg->{$w} if ($rg && (ref($rg) eq 'HASH') && exists($rg->{$w}));
 return;
}

####################################################################################################
1;
