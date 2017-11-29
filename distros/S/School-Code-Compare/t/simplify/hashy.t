use strict;
use v5.22;

use Test::More tests => 6;

use File::Slurp;
use School::Code::Simplify::Comments;

my $simplifier = School::Code::Simplify::Comments->new();

my @lines = read_file( 't/simplify/hashy/miniperl.pl', binmode => ':utf8' );

my $clean = $simplifier->hashy(\@lines);

is($clean->{visibles}, 'usestrict;usev5.22;say"Hi!";', 'perlmini_visibles');
is($clean->{signes},   ';.;"!";', 'perlmini_signes');
is($clean->{signes_ordered}, '"!";.;;', 'perlmini_signesordered');


@lines = read_file( 't/simplify/hashy/perl.pl', binmode => ':utf8' );

$clean = $simplifier->hashy(\@lines);

is($clean->{visibles}, 'usestrict;usewarnings;usev5.22;my@array=qw(99hello1world);foreachmy$word(@array){if($word!~/\d/){print$word;}}say\'\';my$msg=<<\'END\';That\'sit.Whe\'redone!ENDprint$msg;__END__:-)', 'perl_visibles');
is($clean->{signes},   ';;.;@=();$(@){($!~/\/){$;}}\'\';$=<<\'\';\'.\'!$;____:-)', 'perl_signes');
is($clean->{signes_ordered}, '$(@){$;$;$=<<\'\';\'!\'\';\'.($!~/\/){.;:-);;@=();____}}', 'perl_signesordered');
