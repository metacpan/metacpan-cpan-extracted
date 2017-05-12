use Data::Dumper;
use Test::More qw(no_plan);
use Test::Exception;

unless ($ENV{MEMCACHEDS}) {
    diag ("no MEMCACHEDS environment variable defined, tests skipped");
    ok (1, 'so be it');
    exit;
}

diag ("working with $ENV{MEMCACHEDS}");
my @servers = split /\s+/, $ENV{MEMCACHEDS}; #qw(monda:11211);

use_ok ('TM::ResourceAble::MemCached');


# TODO invalid server

# TODO clear map optionally

use constant DONE => 1;

my $nrt = keys %{ $TM::infrastructure->{mid2iid} };
my $nra = keys %{ $TM::infrastructure->{assertions} };

if (DONE) {
    throws_ok { 
	my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/');
    } qr/servers/, 'memcached missing';

#    throws_ok {
#	use Fcntl;
#	my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/', 
#						  servers => \@servers,
#						  mode => O_TRUNC);
#    } qr/no.+map/, 'no map';

    use Fcntl;
    my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/', 
					      servers => \@servers,
					      mode => O_TRUNC | O_CREAT,
	     );
    isa_ok ($tm, 'TM');
    is ($tm->baseuri, 'http://whereever/', 'baseuri recover');

    ok ($tm->tids ('isa'), 'found isa');

#warn Dumper $tm->{assertions};
}

if (DONE) {
    my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/', 
					      servers => \@servers,
					      mode => O_TRUNC,
	);
    is ((scalar $tm->asserts),                $nra, 'default asserts');
    is ((scalar $tm->toplets),                $nrt, 'default toplets');
}

if (DONE) {
    my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/', 
					      servers => \@servers,
					      mode => O_TRUNC,
	);
    $tm->internalize ('rumsti' =>   'http://rumsti');
    $tm->internalize ('rumsti' => \ 'http://ramsti');
#    warn Dumper $tm->toplet ('http://whereever/rumsti');
#    exit;

    is ($tm->tids (  'rumsti'), 'http://whereever/rumsti',       'found rumsti');
    ok ($tm->tids (  'rumsti'),        'found rumsti');
    ok ($tm->tids (  'http://rumsti'), 'found rumsti');
    ok ($tm->tids (\ 'http://ramsti'), 'found rumsti');

    $tm->internalize ('ramsti');
    my $a = Assertion->new (type    => 'is-subclass-of',
			    roles   => [ 'subclass', 'superclass' ],
			    players => [ $tm->tids ('rumsti', 'ramsti') ]);
    $tm->assert ($a);                                    # add that to map

    is ((scalar $tm->asserts),                $nra+1, 'asserts');
    is ((scalar $tm->toplets),                $nrt+2, 'toplets');
#warn Dumper $tm->{assertions};
}

if (DONE) { # regain
    my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/', 
					      servers => \@servers);

#warn Dumper $tm->{mid2iid};
    is ((scalar $tm->asserts),                $nra+1, 'asserts');
    is ((scalar $tm->toplets),                $nrt+2, 'toplets');

    is ($tm->tids (  'rumsti'), 'http://whereever/rumsti',       'refound rumsti');
    ok ($tm->tids (  'rumsti'),        'refound rumsti');

#    warn Dumper $tm->toplet ('http://whereever/rumsti');

    ok ($tm->tids (  'http://rumsti'), 'refound rumsti');
    ok ($tm->tids (\ 'http://ramsti'), 'refound rumsti');
}

if (DONE) { # second map, no crosstalk
    my $tm = new TM::ResourceAble::MemCached (baseuri => 'http://whatever/', 
					      servers => \@servers);

    $tm->internalize ('rumsti' =>   'http://rumsti');
    $tm->internalize ('rumsti' => \ 'http://ramsti');
    $tm->internalize ('romsti');
    my $a = Assertion->new (type    => 'is-subclass-of',
			    roles   => [ 'subclass', 'superclass' ],
			    players => [ $tm->tids ('rumsti', 'romsti') ]);
    $tm->assert ($a);                                    # add that to map

#warn Dumper $tm->{mid2iid};
    is ((scalar $tm->asserts),                $nra+1, 'asserts, 2nd map');
    is ((scalar $tm->toplets),                $nrt+2, 'toplets, 2nd map');

    {
	my $tm2 = new TM::ResourceAble::MemCached (baseuri => 'http://whereever/', 
						   servers => \@servers);
	is ((scalar $tm2->asserts),                $nra+1, 'asserts, 1st map');
	is ((scalar $tm2->toplets),                $nrt+2, 'toplets, 1st map');
    }

}
