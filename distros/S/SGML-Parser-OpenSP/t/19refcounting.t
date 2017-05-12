# 19refcounting.t -- ...
#
# $Id: 19refcounting.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## Parser refcounting
#########################################################

# this is not exactly what I want, the issue here is that
# I would like to tell whether in this cleanup process is
# an attempt to free an unreferenced scalar for which Perl
# would not croak but write to STDERR

lives_ok
{
    my $x = SGML::Parser::OpenSP->new;
    my $y = \$x;
    undef $x;
    undef $y;
} 'parser refcounting 1';

lives_ok
{
    my $x = SGML::Parser::OpenSP->new;
    my $y = \$x;
    undef $y;
    undef $x;
} 'parser refcounting 2';

