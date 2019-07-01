use strict;
use v5.6.0;

use Test::More tests => 9;

use File::Slurp;
use School::Code::Compare::Charset;

########
# MINI #
########

my @lines = read_file( 'xt/data/perl/miniperl.pl', binmode => ':utf8' );

# VISIBLES

my $charset = School::Code::Compare::Charset->new()->set_language('hashy');

my $visibles = join '', @{$charset->get_visibles(\@lines)};

is($visibles, 'usestrict;usev5.22;say"Hi!";', 'perlmini_charset_visibles');

# NUMSIGNES

my $numsignes = join '', @{$charset->get_numsignes(\@lines)};

is($numsignes, 'aa;aa0.0;a"a!";', 'perlmini_charset_numsignes');

# SIGNES

my $signes = join '', @{$charset->get_signes(\@lines)};

is($signes, ';.;"!";', 'perlmini_charset_signes');

# SIGNES ORDERED

$charset = School::Code::Compare::Charset->new()->set_language('hashy');

my $signes         = $charset->get_signes(\@lines);
my $signes_ordered = $charset->sort_by_lines($signes);

is(join('', @{$signes_ordered}), '"!";.;;', 'perlmini_signesordered');

$charset = School::Code::Compare::Charset->new()->set_language('hashy');

my $visibles         = $charset->get_visibles(\@lines);
my $visibles_ordered = $charset->sort_by_lines($visibles);

is(join('', @{$visibles_ordered}), 'say"Hi!";usestrict;usev5.22;', 'perlmini_charset_visiblesordered');

############

@lines = read_file( 'xt/data/perl/nine_off/perl.pl', binmode => ':utf8' );

$charset  = School::Code::Compare::Charset->new()->set_language('hashy');

$visibles = join '', @{$charset->get_visibles(\@lines)};

is($visibles, 'usestrict;usewarnings;usev5.22;my@array=qw(99hello1world);foreachmy$word(@array){if($word!~/\d/){print$word;}}say\'\';my$msg=<<\'END\';That\'sit.Whe\'redone!ENDprint$msg;__END__:-)', 'perl_visibles');

$signes = join '', @{$charset->get_signes(\@lines)};

is($signes, ';;.;@=();$(@){($!~/\/){$;}}\'\';$=<<\'\';\'.\'!$;:-)', 'perl_charset_signes');

$charset = School::Code::Compare::Charset->new()->set_language('hashy');

$signes         = $charset->get_signes(\@lines);
$signes_ordered = $charset->sort_by_lines($signes);

is(join('', @{$signes_ordered}), '$(@){$;$;$=<<\'\';\'!\'\';\'.($!~/\/){.;:-);;@=();}}', 'perl_charset_signesordered');

$charset = School::Code::Compare::Charset->new()->set_language('hashy');

$visibles         = $charset->get_visibles(\@lines);
$visibles_ordered = $charset->sort_by_lines($visibles);

is(join('', @{$visibles_ordered}), ':-)ENDThat\'sit.Whe\'redone!__END__foreachmy$word(@array){if($word!~/\d/){my$msg=<<\'END\';my@array=qw(99hello1world);print$msg;print$word;say\'\';usestrict;usev5.22;usewarnings;}}', 'perl_charset_visiblesordered');
