#!perl

##################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/t/20_policies_codelayout.t $
#     $Date: 2008-05-18 17:07:35 -0700 (Sun, 18 May 2008) $
#   $Author: clonezone $
# $Revision: 2368 $
##################################################################

use 5.006;
use strict;
use warnings;
use utf8;
use Test::More tests => 5;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'CodeLayout::RequireASCII';
is( pcritique($policy, \$code), 0, $policy.' - empty');
#----------------------------------------------------------------

$code = <<'END_PERL';
'0123456789';
'abcdefghijklmnopqrstuvwxyz';
'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
'`~!@#$%^&*()_+-=[]{}\\|;:<>,./?"';
"	";
"";
print <<'EOF';
'0123456789';
'abcdefghijklmnopqrstuvwxyz';
'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
'`~!@#$%^&*()_+-=[]{}\\|;:<>,./?"';
"	";
"";
EOF
END_PERL

$policy = 'CodeLayout::RequireASCII';
is( pcritique($policy, \$code), 0, $policy.' - valid ASCII');
#----------------------------------------------------------------

$code = <<'END_PERL';
print "日本語\n";
END_PERL

$policy = 'CodeLayout::RequireASCII';
is( pcritique($policy, \$code), 1, $policy.' - UTF-8 (Japanese)');
#----------------------------------------------------------------

$code = <<'END_PERL';
print <<'EOF';
áéíóú
âêîôû
äëïöü
õãñ
ÁÉÍÓÚ
ÂÊÎÔÛ
ÄËÏÖÜ
ÕÃÑ
EOF
END_PERL

$policy = 'CodeLayout::RequireASCII';
is( pcritique($policy, \$code), 1, $policy.' - UTF-8 (accented characters)');
#----------------------------------------------------------------

$code = <<'END_PERL';
print <<'EOF';
ç¥¡™£¢∞§¶•ªº
œ∑®†¥øπåß∂ƒ©˙∆˚¬Ω≈ç√∫µ
≤≥…æ“‘’”ÆÚ˘¯
EOF
END_PERL

$policy = 'CodeLayout::RequireASCII';
is( pcritique($policy, \$code), 1, $policy.' - UTF-8 (random option-keys from my Mac keyboard)');

#----------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
