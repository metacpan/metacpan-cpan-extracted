## Domain Registry Interface, EPP Message for SIDN
##
## Copyright (c) 2009,2010 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SIDN::Message;

use strict;
use warnings;

use base qw/Net::DRI::Protocol::EPP::Message/;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

####################################################################################################

sub parse
{
 my $self=shift;
 $self->SUPER::parse(@_);

 ## Parse sidn:ext
 my $result=$self->get_extension('sidn','ext');
 return unless $result;
 my $ns=$self->ns('sidn');
 $result=$result->getChildrenByTagNameNS($ns,'response');
 return unless $result->size();

 ## We add it to the latest status extra_info seen.
 foreach my $el ($result->get_node(1)->getChildrenByTagNameNS($ns,'msg'))
 {
  ## code is mandatory, as well as text probably, field is optional
  $self->add_to_extra_info({from => 'sidn', type => 'text', code => $el->getAttribute('code'),field => $el->getAttribute('field'), message => $el->textContent()});
 }
}

####################################################################################################
1;

__END__

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SIDN::Message - EPP SIDN Message for Net::DRI

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

Copyright (c) 2009,2010 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut
