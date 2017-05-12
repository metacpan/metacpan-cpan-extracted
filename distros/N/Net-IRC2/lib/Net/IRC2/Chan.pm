#
# Copyright 2005, Karl Y. Pradene <knotty@cpan.org> All rights reserved.
#

package Net::IRC2::Chan         ;

use strict;      use warnings   ;
use Exporter                    ;

our @ISA       = qw( Exporter ) ;
our @EXPORT_OK = qw( new      ) ;
our @Export    = qw( new      ) ;

use vars qw( $VERSION )         ;
$VERSION =                      '0.27' ;

sub new        { shift and return bless { @_ } }

 
{   my ( $code, $name ) = q{ sub { return $_[0]->{NAME} = $_[1] || $_[0]->{NAME} } }      ;
    no strict 'refs'                                                                      ;
    foreach $name qw( name topic ) {
	$_ = $code ; s/NAME/$name/g ; *{$name} = eval                                   } }


no strict ;
map { *{$_} = eval 'sub { return $_[0]->{'.$_.'} = $_[1] || $_[0]->{'.$_.'} }'
    } qw ( name topic );
use strict;


1;

__END__

=head1 NAME

Net::IRC2::Chan - ( VaporWare ! ) A channel object on a connection

=head1 WARNING

Not yet implemented

=head1 FUNCTIONS

=over

=item new()

=item name()

=item topic()

=back

=head1 SEE ALSO

Net::IRC2, Net::IRC2::Connection, Net::IRC2::Event

=head1 AUTHOR

Karl Y. Pradene, C<< <knotty@cpan.org>, irc://knotty@freenode.org/ >> 

=head1 COPYRIGHT & LICENSE

Copyright 2005, Karl Y. Pradene <knotty@cpan.org> All rights reserved.

This program is released under the following license: GNU General Public License, version 2

This program is free software; you can redistribute it and/or modify it under the terms
of the GNU General Public License version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program;
if not, write to the 

 Free Software Foundation,
 Inc., 51 Franklin St, Fifth Floor,
 Boston, MA  02110-1301 USA

See L<http://www.fsf.org/licensing/licenses/gpl.html>

=cut

__END__

