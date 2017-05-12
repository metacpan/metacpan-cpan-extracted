#!perl

##################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/t/20_policies_modules.t $
#     $Date: 2008-05-18 17:07:35 -0700 (Sun, 18 May 2008) $
#   $Author: clonezone $
# $Revision: 2368 $
##################################################################

use 5.006;
use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More tests => 12;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

# without Perl::MinimumVersion, some policies always pass.
eval { require Perl::MinimumVersion; };
my $has_minimum_version = $EVAL_ERROR ? 0 : 1;

#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 1, $policy.' - empty');
#----------------------------------------------------------------

$code = <<'END_PERL';
package Foo;
use strict;
use warnings;
1;
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 1, $policy.' - package');
#----------------------------------------------------------------

$code = <<'END_PERL';
#!perl -w
use strict;
print "ok\n";
{
   no strict;
}
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 1, $policy.' - shebang');
#----------------------------------------------------------------

$code = <<'END_PERL';
use 5.006;
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 0, $policy.' - 5.006');
#----------------------------------------------------------------

$code = <<'END_PERL';
use 5.006001;
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 0, $policy.' - 5.006001');
#----------------------------------------------------------------

$code = <<'END_PERL';
use v5;
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 0, $policy.' - v5');
#----------------------------------------------------------------

$code = <<'END_PERL';
use v5.6;
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 0, $policy.' - v5.6');
#----------------------------------------------------------------

$code = <<'END_PERL';
use v5.6.0;
END_PERL

$policy = 'Modules::RequirePerlVersion';
is( pcritique($policy, \$code), 0, $policy.' - v5.6.0');
#----------------------------------------------------------------

$code = <<'END_PERL';
our $foo;
END_PERL

$policy = 'Modules::PerlMinimumVersion';
%config = ( version => '5.005' );
is( pcritique($policy, \$code, \%config), $has_minimum_version, $policy.' - 5.005');
%config = ( version => '5.006' );
is( pcritique($policy, \$code, \%config), 0, $policy.' - 5.006');
%config = ( version => '5.008' );
is( pcritique($policy, \$code, \%config), 0, $policy.' - 5.008');

%config = ( version => '9.999' );
eval { pcritique($policy, \$code, \%config); };
ok($EVAL_ERROR, $policy.' - invalid version');

#----------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
