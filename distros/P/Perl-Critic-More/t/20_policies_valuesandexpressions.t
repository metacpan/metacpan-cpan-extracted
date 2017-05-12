#!perl

##################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/t/20_policies_valuesandexpressions.t $
#     $Date: 2008-05-18 17:07:35 -0700 (Sun, 18 May 2008) $
#   $Author: clonezone $
# $Revision: 2368 $
##################################################################

use 5.006;
use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More tests => 9;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
is( pcritique($policy, \$code), 0, $policy.' - empty');
#----------------------------------------------------------------

$code = <<'END_PERL';
'1234567890abcdefghijklmnop';
"1234567890abcdefghijklmnop";
q{1234567890abcdefghijklmnop};
qq{1234567890abcdefghijklmnop};
END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
is( pcritique($policy, \$code), 0, $policy.' - typical strings');
#----------------------------------------------------------------
$code = <<'END_PERL';
'1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890';
"1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890";
q{1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890};
qq{1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890};
END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
is( pcritique($policy, \$code), 4, $policy.' - long strings');
#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo {
    '1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890';
    "1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890";
    q{1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890};
    qq{1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890};
}
END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
is( pcritique($policy, \$code), 3, $policy.' - long strings in a subroutine');
#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = sub {
    '1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890';
}
END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
is( pcritique($policy, \$code), 0, $policy.' - long strings in anon sub');
#----------------------------------------------------------------

$code = <<'END_PERL';

sub foo {
    '1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890';
    "1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890";
    q{1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890};
    qq{1234567890abcdefghijklmnopqrstuvwxyz_1234567890abcdefghijklmnopqrstuvwxyz_1234567890};
}
END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
%config = ( max_length => '100' );
is( pcritique($policy, \$code, \%config), 0, $policy.' - configured maxline length');
#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
%config = ( max_length => ' -1 ' );
eval { pcritique($policy, \$code, \%config); };
ok( $EVAL_ERROR, $policy.' - invalid configuration');
#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
%config = ( max_length => ' 0 ' );
eval { pcritique($policy, \$code, \%config); };
ok( $EVAL_ERROR, $policy.' - invalid configuration');
#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'ValuesAndExpressions::RestrictLongStrings';
%config = ( max_length => '0xff' );
eval { pcritique($policy, \$code, \%config); };
ok( $EVAL_ERROR, $policy.' - invalid configuration');

#----------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
