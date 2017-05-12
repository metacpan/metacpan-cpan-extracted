## Domain Registry Interface, RRP Session commands
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::RRP::Core::Session;

use strict;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.7 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Core::Session - RRP Session commands for Net::DRI

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

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


###############################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( _describe => [ \&describe, \&describe_parse ],
           logout    => [ \&quit ],
           login     => [ \&session ],
         );

 $tmp{noop}=$tmp{_describe}; ## alias for keepalive
 return { 'session' => \%tmp };
}

sub describe
{
 my ($rrp,$what)=@_;
 my $mes=$rrp->message();
 $mes->command('describe');
 $mes->options('Target',$what) if $what;
}

sub describe_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 $rinfo->{session}->{describe}->{protocol}=$mes->entities('protocol');
}

sub quit
{
 my ($rrp)=@_;
 my $mes=$rrp->message();
 $mes->command('quit');
}

sub session
{
 my ($rrp,$id,$pass,$newpass)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters('login & password') unless (defined($id) && $id && defined($pass) && $pass);

 my $mes=$rrp->message();
 $mes->command('session');
 $mes->options('Id',$id);
 $mes->options('Password',$pass);
 $mes->options('NewPassword',$newpass) if (defined($newpass) && $newpass && ($newpass ne $pass));
}

###############################################################################################
1;
