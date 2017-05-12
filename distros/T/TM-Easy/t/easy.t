use strict;
use warnings;

use Test::More qw(no_plan);

use Data::Dumper;

require_ok('TM::Easy');

{
    my $mm = new TM::Easy (inline => '
aaa (bbb)
');
    foreach (qw(aaa bbb)) {
	ok (exists $mm->{$_}, "$_ exists");
    }
}



my $mm = new TM::Easy (inline => <<EOM );         # from then on....

rho (person) reifies http://address.com/
bn: Robsi
bn: Robert
bn (nickname): drrho
bn: Bertl
oc (homepage): http://kill1.devc.at/
oc (homepage): http://kill2.devc.at/
oc (blog)    : http://kill3.devc.at/
sin: http://indicator1.com/
sin: http://indicator2.com/


sacklpicka (cat)
bn: Sacklpicka

(owns)
owner: sacklpicka
owned: rho

(likes)
liker: rho
object: perl

(likes)
liker: rho
object: java

java
bn: Java

perl
bn: Perl

forth
bn: Forth

(hates)
hater: rho
object: java forth

EOM

{ # map as whole
    my $tm = $mm->map;
    ok (eq_set ([ map { $_->[TM->LID]} $tm->toplets ], [ keys %$mm ]), 'all toplets as pseudo keys');

    ok (! exists $mm->{hubert}, 'hubert does not exist');

    ok (exists $mm->{'http://address.com/ = '}, 'rho via addr');
    ok (exists $mm->{'http://indicator1.com/'}, 'rho via sin 1');
    ok (exists $mm->{'http://indicator2.com/'}, 'rho via sin 2');
    ok (       $mm->{'http://address.com/ = '}, 'rho via addr');
    ok (       $mm->{'http://indicator1.com/'}, 'rho via sin 1');
    ok (       $mm->{'http://indicator2.com/'}, 'rho via sin 2');
}

{ # names and occs
    my $rho = $mm->{rho};
    ok (eq_set ($rho->{name_s},
		[
		 'Robsi',
		 'Robert',
		 'Bertl',
		 'drrho'
		 ]), 'topic names');
    ok (eq_set ($rho->{nickname_s},
		[
		 'drrho'
		 ]), 'topic name subtype');
    ok (eq_set ($rho->{occurrence_s},
		[
		 'http://kill1.devc.at/',
		 'http://kill2.devc.at/',
		 'http://kill3.devc.at/'
		 ]), 'topic occurrences');
    ok (eq_set ($rho->{blog_s},
		[
		 'http://kill3.devc.at/'
		 ]), 'topic occurrence subtype');
    my $n = $rho->{name};
    ok ((grep { $n eq $_ } (
			   'Robsi',
			   'Robert',
			   'Bertl',
			   'drrho'
			   )), 'topic name');
    $n = $rho->{nickname};
    ok ((grep { $n eq $_ } (
			   'drrho'
			   )), 'topic name');
    $n = $rho->{blog};
    ok ((grep { $n eq $_ } (
			   'http://kill3.devc.at/'
			   )), 'topic name');

}

{
    my $rho = $mm->{rho};

    is ($rho->{-owned}->{owner}->{name}, "Sacklpicka", 'direct assoc traversal');


#    is ($rho->{'<- owned -> owner'}->{name}, "Sacklpicka", 'direct assoc traversal, <- .. -> ');
}

{
    my $tm = $mm->map;
    my $a = $mm->{rho}->{-owned};
    ok (eq_set ([ keys %$a ], [ $tm->tids ('owner', 'owned') ]), 'all roles as pseudo keys');

    is ($a->{owner}->{name},     'Sacklpicka', 'role1');
    is ($a->{owned}->{nickname}, 'drrho',      'role2');

    $a = $mm->{rho}->{'<- owned'};
    ok (eq_set ([ keys %$a ], [ $tm->tids ('owner', 'owned') ]), 'all roles as pseudo keys');

    is ($a->{owner}->{name},         'Sacklpicka', 'role1, short');
    is ($a->{' -> owner'}->{name},   'Sacklpicka', 'role1, long');

    is ($a->{owned}->{nickname},     'drrho',      'role2, short');
    is ($a->{'->owned'}->{nickname}, 'drrho',      'role2, long');

    my @a = @{ $mm->{rho}->{-liker_s} };
    is (scalar @a, 2, 'all likings');

    foreach my $a (@a) {
	is ($a->{liker}->{'!'}, 'tm://nirvana/rho', 'liker');
	ok ((grep { $a->{object}->{name} eq $_ } qw(Java Perl)), 'liked object');
    }

    @a = @{ $mm->{rho}->{'<- liker_s'} };
    is (scalar @a, 2, 'all likings');

    foreach my $a (@a) {
	is ($a->{liker}->{'!'}, 'tm://nirvana/rho', 'liker');
	ok ((grep { $a->{object}->{name} eq $_ } qw(Java Perl)), 'liked object');
    }


    $a = $mm->{rho}->{-hater};
    ok (eq_set ([ map { $_->{name} } @{ $a->{object_s} }],
		[ 'Java', 'Forth' ]),               'hate objects');


}

{
    my $tm = $mm->map;

    ok (eq_set ([ map {$_->{name}} @{ $mm->{rho}->{'<-> likes'} } ], [ 'Perl', 'Java' ]), 'all on other side');
}

{
    is ($mm->{rho}->{'!'}, 'tm://nirvana/rho', 'topic id');
    is ($mm->{rho}->{'='}, 'http://address.com/', 'subject address');
    ok (eq_set ($mm->{rho}->{'~'}, [ 
				     'http://indicator1.com/',
				     'http://indicator2.com/' 
				     ]), 'subject indicators');
}

__END__







$rho->{names} # a list
$rho->{'/name'} # same

$rho->{names}->[0]

$rho->{names@de}    # still a list

$rho->{name@de} # single name, undef if there is none

$rho->{nickname}

$rho->{'/ homepage'};
$rho->{homepage};

$rho->{<<_husband}->{>>_wife}


my ($anitta) = $rho->{players_husband} -> { 'wife'};

($anitta) = $rho->{'<- husband'}->{'-> wife'};

__END__




#use TM::DM::Tied;
my $t = new TM::DM::Tied::Topic ('rho');

warn Dumper $t->{names};

warn $t->{names}->[3];

warn $t->{homepage};

warn $t->{roles}->{author};

warn $t->{roles}->{author}->[0]->{opus}->[0];    # control which one
warn $t->{roles}->{author}->{opus};              # take one

warn $t->{author}->{opus};      # if there is NO author occ, then we look for author roles



#use TM::DM::Tied;
my $t = new TM::DM::Tied::Topic ('rho');

warn Dumper $t->{names};

warn $t->{names}->[3];

warn $t->{homepage};

warn $t->{roles}->{author};

warn $t->{roles}->{author}->[0]->{opus}->[0];    # control which one
warn $t->{roles}->{author}->{opus};              # take one

warn $t->{author}->{opus};      # if there is NO author occ, then we look for author roles


