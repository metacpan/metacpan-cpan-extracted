use Perl6::Rules;
use Test::Simple 'no_plan';

rule abc {abc}


rule once {<abc>}

ok( "abcabcabcabcd" =~ m/<once>/, 'Once match' );
ok( $0, 'Once matched' );
ok( $0->[0] eq "abc", 'Once matched' );
ok( @$0 == 1, 'Once no array capture' );
ok( keys %$0 == 0, 'Once no hash capture' );


rule rep {<abc><4>}

ok( "abcabcabcabcd" =~ m/<rep>/, 'Rep match' );
ok( $0, 'Rep matched' );
ok( $0->[0] eq "abcabcabcabc", 'Rep matched' );
ok( @$0 == 1, 'Rep no array capture' );
ok( keys %$0 == 0, 'Rep no hash capture' );


rule cap {<?abc>}

ok( "abcabcabcabcd" =~ m/<?cap>/, 'Cap match' );
ok( $0, 'Cap matched' );
ok( $0->[0] eq "abc", 'Cap zero matched' );
ok( $0->{cap} eq "abc", 'Cap captured' );
ok( $0->{cap}[0] eq "abc", 'Cap zero captured' );
ok( $0->{cap}{abc} eq "abc", 'Cap abc captured' );
ok( $0->{cap}{abc}[0] eq "abc", 'Cap abc zero captured' );
ok( @$0 == 1, 'Cap no array capture' );
ok( keys %$0 == 1, 'Cap hash capture' );


rule repcap {<?abc><4>}

ok( "abcabcabcabcd" =~ m/<?repcap>/, 'Repcap match' );
ok( $0, 'Repcap matched' );
ok( $0->[0] eq "abcabcabcabc", 'Repcap matched' );
ok( $0->{repcap} eq "abcabcabcabc", 'Repcap captured' );
ok( $0->{repcap}{abc}[0] eq "abc", 'Repcap abc zero captured' );
ok( $0->{repcap}{abc}[1] eq "abc", 'Repcap abc one captured' );
ok( $0->{repcap}{abc}[2] eq "abc", 'Repcap abc two captured' );
ok( $0->{repcap}{abc}[3] eq "abc", 'Repcap abc three captured' );
ok( @$0 == 1, 'Repcap no array capture' );


rule caprep {(<abc><4>)}

ok( "abcabcabcabcd" =~ m/<?caprep>/, 'Caprep match' );
ok( $0, 'Caprep matched' );
ok( $0->[0] eq "abcabcabcabc", 'Caprep matched' );
ok( $0->{caprep} eq "abcabcabcabc", 'Caprep captured' );
ok( $0->{caprep}[1] eq "abcabcabcabc", 'Caprep abc one captured' );
