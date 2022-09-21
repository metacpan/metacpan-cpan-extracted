use strict;
use warnings;
use Test::More;
use File::Temp;
use Pod::Spell;

my $podfile = File::Temp->new;
my $textfile = File::Temp->new;

print $podfile "\n=head1 TEST undef\n"
    . "\n=begin stopwords\n"
    . "\nPleumgh zpaph myormsp snickh\n\n"
    . "\nblah blargh bazh\n\n"
    . "\n=end stopwords\n"
    ;

# reread from beginning
$podfile->seek( 0, 0 );

my $p = new_ok 'Pod::Spell' => [ debug => 1 ];

$p->parse_from_filehandle( $podfile, $textfile );

my $wordlist = $p->stopwords->wordlist;

ok $wordlist->{$_}, "stopword added: $_"
  for qw( Pleumgh zpaph myormsp snickh blah blargh bazh );

done_testing;
