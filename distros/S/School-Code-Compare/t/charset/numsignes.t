use strict;
use v5.6.0;

use Test::More tests => 1;

use File::Slurp;
use School::Code::Compare::Charset::NumSignes;

########
# MINI #
########

my @lines = read_file( 'xt/data/perl/miniperl.pl', binmode => ':utf8' );
# use strict;
# use v5.22;
# 
# # Hello World
# say "Hi!";

my $numsigns_maker = School::Code::Compare::Charset::NumSignes->new();

my $numsignes = join '', @{$numsigns_maker->filter(\@lines)};
# a a;
# a a0.0;
# 
# # a a
# a "a!";

is($numsignes, "a a;\na a0.0;\n\n# a a\na \"a!\";\n", 'perlmini_numsignes');
