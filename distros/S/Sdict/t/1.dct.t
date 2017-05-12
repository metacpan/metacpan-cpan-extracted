# $RCSfile: 1.dct.t,v $
# $Author: swaj $
# $Revision: 1.1 $

use Test;
BEGIN { plan tests => 13 };
use Sdict;
print "# I'm testing Sdict version $Sdict::VERSION\n";

$Sdict::debug = 1;
my $sd = Sdict->new;
# 1
ok($sd);

$sd->init ( { file => 't/test.dct' } );
# 2
ok($sd->load_dictionary_fast);

my $size = scalar ( @{ $sd->{ sindex_1 } } );
# 3
ok ($size==3);

# 4
ok ($sd->{header}->{title} eq 'title');

# 5
ok ($sd->{header}->{copyright} eq 'copyright');

# 6
ok ($sd->{header}->{a_lang} eq 'en');

# 7
ok ($sd->{header}->{w_lang} eq 'en');

# 8
ok ($sd->{header}->{version} eq '1.0');

# 9 
ok ($sd->{header}->{words_total} == 3);

# 10
my $word = $sd->get_next_word;
ok ($word eq 'a');

# 11
$word = $sd->get_next_word;
ok ($word eq 'b');

# 12
my $art = $sd->search_word ('d');
ok (!$art);

# 13 
$art = $sd->search_word ('c');
ok ($art eq 'letter c' );

$sd->unload_dictionary;


__END__
