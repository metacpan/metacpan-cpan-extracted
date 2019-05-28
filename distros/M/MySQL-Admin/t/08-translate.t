#use lib qw(lib/);
use Cwd;

use strict;
use vars qw($lang);
use Test::More tests => 2;
use MySQL::Admin::Translate;
loadTranslate(getcwd()."/cgi-bin/config/translate.pl");
*lang = \$MySQL::Admin::Translate::lang;
ok( $lang->{de}{right_passwort_text} eq 'Ok' );
ok( $lang->{en}{editmysqluserrights} eq 'Rights' );
