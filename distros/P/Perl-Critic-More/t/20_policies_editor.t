#!perl

##################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/t/20_policies_editor.t $
#     $Date: 2008-05-18 17:07:35 -0700 (Sun, 18 May 2008) $
#   $Author: clonezone $
# $Revision: 2368 $
##################################################################

use 5.006;
use strict;
use warnings;
use Test::More tests => 13;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - no file vars, no shebang');

#----------------------------------------------------------------

$code = <<'END_PERL';
#! /usr/bin/perl
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - no file vars, w/ simple shebang');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!perl -w -*- cperl -*-
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line, w/ perl arg');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!perl -w # -*- cperl -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line, w/ perl arg, w/ comment');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!perl # -*- cperl -*-
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line, w/o perl arg, w/ comment');

#----------------------------------------------------------------

$code = <<'END_PERL';
# -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line, mode only');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl -w -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line, shebang w/ perl arg');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
# -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - second line');

#----------------------------------------------------------------

$code = <<'END_PERL';
# random non-shebang comment...
# -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - fake second line, no shebang');

#----------------------------------------------------------------

$code = <<'END_PERL';
/usr/bin/perl -w
foo();
# Local Variables:
# End:
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - multi-line');

#----------------------------------------------------------------

$code = <<"END_PERL";
foo();
\f
# Local Variables:
# End:
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - multi-line, after page break');

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();
# Local Variables:
# End:
END_PERL
$code .= 'A' x 3000;

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - fake multi-line, too early');

#----------------------------------------------------------------

$code = <<"END_PERL";
foo();
# Local Variables:
# End:
\f
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - fake multi-line, before page break');

__END__


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
