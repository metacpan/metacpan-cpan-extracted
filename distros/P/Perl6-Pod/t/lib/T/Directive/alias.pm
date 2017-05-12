#===============================================================================
#
#  DESCRIPTION:  Test alias directive
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package T::Directive::alias;
use strict;
use warnings;
use Test::More;
use base "TBase";

sub u01_init_aliases : Test  {
    my $t = shift;
    my ( $p, $f, $x ) = $t->parse_to_xml(<<T);
=begin pod
=alias PROGNAME    Earl Irradiatem Evermore
=alias VENDOR      4D Kingdoms
=alias TERMS_URLS  =item L<http://www.4dk.com/eie>
=                  =item L<http://www.4dk.co.uk/eie.io/>
=                  =item L<http://www.fordecay.ch/canttouchthis>
=end pod
T
    is_deeply $p->current_context->{_alias}, {
           'PROGNAME' => 'Earl Irradiatem Evermore',
           'TERMS_URLS' => '=item L<http://www.4dk.com/eie>
=item L<http://www.4dk.co.uk/eie.io/>
=item L<http://www.fordecay.ch/canttouchthis>',
           'VENDOR' => '4D Kingdoms'
         };
;

}
1;

