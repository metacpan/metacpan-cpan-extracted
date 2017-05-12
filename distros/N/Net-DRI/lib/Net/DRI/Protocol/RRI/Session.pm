## Domain Registry Interface, RRI Session commands (DENIC-11)
##
## Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::RRI::Session;

use strict;

use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRI::Session - RRI Session commands (DENIC-11) for Net::DRI

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

Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
           connect => [ \&hello ],
         );

 return { 'session' => \%tmp };
}

sub hello ## should trigger a greeting from server, allowed at any time
{
 my ($rri)=@_;
 my $mes=$rri->message();
 $mes->command(['hello']);
}

sub logout
{
 my ($rri)=@_;
 my $mes=$rri->message();
 $mes->command(['logout']);
}

sub login
{
 my ($rri,$id,$pass,$newpass,$opts)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('login & password') unless (defined($id) && $id && defined($pass) && $pass);

 Net::DRI::Exception::usererr_invalid_parameters('login')    unless Net::DRI::Util::xml_is_token($id,3,16);
 Net::DRI::Exception::usererr_invalid_parameters('password') unless Net::DRI::Util::xml_is_token($pass,6,16);

 my $mes=$rri->message();
 $mes->command(['login']);
 my @d;
 push @d,['user',$id];
 push @d,['password',$pass];

 $mes->command_body(\@d);
}

####################################################################################################
1;
