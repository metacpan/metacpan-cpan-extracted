package MyMapSphere;

use TM;
use base qw(TM);
use Class::Trait ('TM::MapSphere',
		  'TM::Synchronizable::MLDBM' => {
		      exclude => [ "sync_in", "sync_out" ] # these are provided by TM::Synchronizable::MapSphere
		  },
		  'TM::Synchronizable::MapSphere');
1;

# test alternative:
# TM::Materialized::MLDBM + TM::MapSphere + TM::Synchronizable::MapSphere (overloads sync)

#-- test suite

use strict;
use warnings;

#use Class::Trait 'debug';

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

use Time::HiRes;

my @tmp;

sub _mktmps {
    foreach (qw(0 1 2 3 4)) {
	use IO::File;
	use POSIX qw(tmpnam);
	do { $tmp[$_] = tmpnam() ;  } until IO::File->new ($tmp[$_], O_RDWR|O_CREAT|O_EXCL);
    }
}


END { map { unlink <$_*> } @tmp; };

sub _writetmp {
    my $fn = shift;
    my $ct = shift;

    my $fh = IO::File->new ("> $fn") || die "so what?";
    print $fh $ct;
    $fh->close;
}

_mktmps;

#== TESTS =====================================================================

{ # very basic tests
    { # create a new sphere, put in some content
	my $tm = new MyMapSphere (url => 'file:'.$tmp[0]);
	$tm->internalize ('aaa' => 'http://AAA/');
	ok ($tm->mids ('aaa'),                            'found topic');
    }
    { # reopen this sphere, check content, should not be there
	my $tm = new MyMapSphere (url => 'file:'.$tmp[0]);
	ok (!$tm->mids ('aaa'),                           'found no topic (no sync)');
    }
    { # try again, this time with sync_out
	my $tm = new MyMapSphere (url => 'file:'.$tmp[0]);
	$tm->internalize ('aaa' => 'http://AAA/');
	ok ($tm->mids ('aaa'),                            'found topic (before sync out)');
	$tm->sync_out;
    }
    { # reopen this sphere, check content, should not be there
	my $tm = new MyMapSphere (url => 'file:'.$tmp[0]);
	ok (!$tm->mids ('aaa'),                           'found no topic (no sync, yet)');
	$tm->sync_in;
	ok ( $tm->mids ('aaa'),                           'found topic (after sync)');
    }
}
{ # now with mounting stuff
    { # create a new sphere, put in some content
	my $tm = new MyMapSphere (url => 'file:'.$tmp[1]);
	$tm->internalize ('aaa' => 'http://AAA/');
	ok ($tm->mids ('aaa'),                            'found topic');

	use TM::Materialized::AsTMa;
	$tm->mount ('/xxx/'     => new TM::Materialized::AsTMa (inline => "ccc (ddd)\n\n"));
	ok ($tm->mids ('xxx'),                            'found map topic');

	# astma map is not sync'ed in
	my $child = $tm->is_mounted ('/xxx/');
	ok (!$child->mids ('ccc'),                        'child has no content');
	$tm->sync_out;
    }
    utime time+1, time+1, $tmp[1];                        # fake that the file is mod'ed in the future
    { # reopen this sphere, check content, should not be there
	my $tm = new MyMapSphere (url => 'file:'.$tmp[1]);
	$tm->sync_in;
#	warn Dumper $tm;
#	exit;

        ok ( $tm->mids ('aaa'),                           'found topic (after sync)');
	ok ( $tm->mids ('xxx'),                           'found map topic');

	ok ( $tm->is_mounted ('/xxx/'),                   'recursive automount for xxx');

	my $child = $tm->is_mounted ('/xxx/');

	ok ($child->mids ('ccc'),                         'child map, midlets');
	ok ($child->mids ('ddd'),                         'child map, midlets');
    }
}

{   # now an empty sphere, and we will add AsTMa children
    my $tm = new MyMapSphere (url => 'file:'.$tmp[2]);
    # one map hangin in, but not loaded
    use TM::Materialized::AsTMa;
    $tm->mount ('/xxx/'     => new TM::Materialized::AsTMa (file => $tmp[3]));
    
    $tm->mount ('/yyy/'     => new TM::Materialized::AsTMa (file => $tmp[4]));
    
    _writetmp ($tmp[3], "ccc (ddd)

implementation
sin: http://tm.devc.at/mapsphere/implementation

yyy (topicmap)
sin: file:$tmp[4]
oc (implementation): TM::Materialized::AsTMa

");  utime time+1, time+1, $tmp[3];
    
    _writetmp ($tmp[4], "eee (fff)

");  utime time+1, time+1, $tmp[4];
    
    # that's all we have for now
    ok ($tm->mids ('xxx'),                             'child map, midlet (xxx)');
    ok ($tm->mids ('yyy'),                             'child map, midlet (yyy)');

    # but not this
    ok (!$tm->is_mounted ('/xxx/')->mids ('ccc'),      'child map, midlet missing (ccc)');
    ok (!$tm->is_mounted ('/xxx/')->mids ('ddd'),      'child map, midlet missing (ddd)');
    ok (!$tm->is_mounted ('/xxx/')->mids ('yyy'),      'child map, midlet missing (yyy)');

    # but now we sync in a subtree
#warn "before global syncin";
    $tm->sync_in ('/xxx/');
    
    ok ( $tm->is_mounted ('/xxx/')->mids ('ccc'),      'child map, midlet (ccc)');
    ok ( $tm->is_mounted ('/xxx/')->mids ('ddd'),      'child map, midlet (ddd)');
    ok ( $tm->is_mounted ('/xxx/')->mids ('yyy'),      'child map, midlet (yyy)');
    
    ok ( $tm->is_mounted ('/xxx/yyy/')->mids ('eee'),  'grandchild map, midlet (eee)');
    ok ( $tm->is_mounted ('/xxx/yyy/')->mids ('fff'),  'grandchild map, midlet (fff)');

    # but still not this
    ok (!$tm->is_mounted ('/yyy/')->mids ('eee'),      'child map, midlet missing (eee)');

    $tm->sync_in ('/yyy/');
    # but now
    ok ( $tm->is_mounted ('/yyy/')->mids ('eee'),      'child map, midlet (eee)');

#	warn Dumper $tm; exit;
}

eval {
    map { unlink <$_*> } @tmp;
}; _mktmps;

{
    {
	my $tm = new MyMapSphere (url => 'file:'.$tmp[2]);
	$tm->mount ('/xxx/'     => new TM::Materialized::MLDBM (file => $tmp[0]));
	$tm->mount ('/yyy/'     => new TM::Materialized::MLDBM (file => $tmp[1]));

	# that's all we have for now
	ok ($tm->mids ('xxx'),                             'child map, midlet (xxx)');
	ok ($tm->mids ('yyy'),                             'child map, midlet (yyy)');
	# but not this
	ok (!$tm->is_mounted ('/xxx/')->mids ('aaa'),      'child map, midlet missing (aaa)');
	ok (!$tm->is_mounted ('/yyy/')->mids ('bbb'),      'child map, midlet missing (bbb)');

	$tm->is_mounted ('/xxx/')->internalize ('aaa' => 'http://AAA/');
	$tm->is_mounted ('/yyy/')->internalize ('bbb' => 'http://AAA/');

	ok ( $tm->is_mounted ('/xxx/')->mids ('aaa'),      'child map, midlet (aaa)');
	ok ( $tm->is_mounted ('/yyy/')->mids ('bbb'),      'child map, midlet (bbb)');

	$tm->sync_out; # should create also the child maps, but they are empty
    }
    use TM::Materialized::MLDBM;
    { # check child map content and then add to it
	my $tm = new TM::Materialized::MLDBM (file => $tmp[0]);
	$tm->sync_in;
	ok ($tm->mids ('aaa'),                             'child map reopened, midlet (aaa)');

	$tm->internalize ('ccc' => 'http://CCC/');
	$tm->sync_out;
    }
    { # check child map content and then add to it
	my $tm = new TM::Materialized::MLDBM (file => $tmp[1]);
	$tm->sync_in;
	ok ($tm->mids ('bbb'),                             'child map reopened, midlet (bbb)');

	$tm->internalize ('ddd' => 'http://DDD/');
	$tm->sync_out;
    }

    { # reopen the sphere
	my $tm = new MyMapSphere (url => 'file:'.$tmp[2]);
	$tm->sync_in ('/', 1); # only the first level

	ok ($tm->mids ('xxx'),                             'child map, midlet (xxx)');
        ok ($tm->mids ('yyy'),                             'child map, midlet (yyy)');
	# but not this
	ok (!$tm->is_mounted ('/xxx/'),                    'child map xxx not mounted');
	ok (!$tm->is_mounted ('/yyy/'),                    'child map yyy not mounted');

	$tm->sync_in ('/xxx/');
	ok ( $tm->is_mounted ('/xxx/')->mids ('aaa'),      'child map xxx, midlet (aaa)');
	ok ( $tm->is_mounted ('/xxx/')->mids ('ccc'),      'child map xxx, midlet (ccc)');

	$tm->sync_in ('/yyy/');
	ok ( $tm->is_mounted ('/yyy/')->mids ('bbb'),      'child map yyy, midlet (bbb)');
	ok ( $tm->is_mounted ('/yyy/')->mids ('ddd'),      'child map yyy, midlet (ddd)');
    }
}


__END__
__END__


    {
	my $ms = new TM::MapSphere;
	
	use TM::ResourceAble::MLDBM;
	$ms->mount ('/'         => new TM::ResourceAble::MLDBM (file => $tmp));
 	$ms->mount ('/xxx/'     => new TM::ResourceAble::MLDBM (file => $tmp2));
# they all have to be in there!
	ok ($ms->is_mounted ('/')->mids ('xxx'),          'again, child map, midlet (xxx)');
	ok ($ms->is_mounted ('/')->mids ('yyy'),          'again, child map, midlet (yyy)');
	ok ($ms->is_mounted ('/xxx/')->mids ('yyy'),      'again, child map, midlet (xxx/yyy)');

	ok (!$ms->is_mounted ('/yyy/'),                   'no recursive automount for yyy');
	ok (!$ms->is_mounted ('/xxx/yyy/'),               'no recursive automount for xxx/yyy');

# now we sync
	$ms->sync_in ('/xxx/');
	ok ( $ms->is_mounted ('/xxx/yyy/'),               'recursive automount for xxx/yyy');
	ok (!$ms->is_mounted ('/yyy/'),                   'no recursive automount for yyy');

# now we sync from the top
	$ms->sync_in ('/');

	ok ( $ms->is_mounted ('/yyy/'),                   'recursive automount for yyy');
	ok ( $ms->is_mounted ('/xxx/yyy/'),               'recursive automount for xxx/yyy');
    }



{
    my $db = { aaa => { bbb => { ccc => undef }},
	       ddd => { eee => undef,
			fff => { ggg => undef },
		    },
	       xxx => { yyy => undef } };

    {
	use TM::MapSphere;
	my $ms = new TM::MapSphere;

	use TM::ResourceAble::MLDBM;
	$ms->mount ('/' => new TM::ResourceAble::MLDBM (file => $tmp3));

	_mount_rec ($ms, '/', $db);

	sub _mount_rec {
	    my $ms   = shift;
	    my $path = shift;
	    my $db   = shift or return;

	    foreach my $child (keys %$db) {
# 		warn "# hooking $child into ". $path . $child . '/';
		use TM::ResourceAble::MLDBM;
		my $path2 = $path . $child . '/';
 		$ms->mount ($path2 => new TM::ResourceAble::MLDBM (file => $tmp3 . '.' . $child, baseuri => 'tm:'.$path . $child . '/'));
 		_mount_rec ($ms, $path2, $db->{$child});
	    }
	}

    }
    {
	use TM::ResourceAble::MLDBM;

	use TM::MapSphere;
	my $mt = new TM::MapSphere;
	$mt->mount ('/' => new TM::ResourceAble::MLDBM (file => $tmp3));

	$mt->sync_in ('/');

#	warn "after ".Dumper $mt; exit;
	_mount_check_rec ($mt, '/', $db);

	sub _mount_check_rec {
	    my $ms   = shift;
	    my $path = shift;
	    my $db   = shift or return;

	    foreach my $child (keys %$db) {
		my $path2 = $path . $child . '/';
		ok ($ms->is_mounted ($path2), "regained $path2");

 		_mount_check_rec ($ms, $path2, $db->{$child});
	    }
	}
    }
    unlink <"$tmp3*">;
}

__END__



{ # try to use automatic selection
   my $ms = new TM::MapSphere (BaseURL => 'file:/tmp/');
   is (ref($ms), 'TM::MapSphere::MLDBM', 'selected MLDBM version');
   is ($ms->{FILEBASE}, '/tmp/', 'correct filebase');

   eval {
       my $ms2 = new TM::MapSphere (BaseURL => 'tm://something/');
       is (ref ($ms2), 'TM::MapSphere::Client', 'selected Client version');
   }; if ($@) {
       like ($@, qr/Can\'t locate/, 'exception ok, client driver not found');
   }

   $ms = new TM::MapSphere; # nothing here => should be memory
   is (ref($ms), 'TM::MapSphere::Memory', 'selected memory version');

   eval {
       $ms = new TM::MapSphere (BaseURL => 'rumsti:xxx');
   }; like ($@, qr/unknown/, 'exception ok, driver not existing');
}

require_ok ('TM::MapSphere::MLDBM');
{
    my $ms = new TM::MapSphere::MLDBM (FileBase => '/tmp/');
    is (ref ($ms), 'TM::MapSphere::MLDBM', 'class ok');
    is ($ms->{FILEBASE}, '/tmp/', 'filebase ok');
    is ($ms->{METANAME}, 'meta',  'metaname ok');
}

require_ok ('TM::MapSphere::Memory');

require_ok ('TM::MapSphere::Dispatch');

{
    my $md = new TM::MapSphere::Dispatch ('/' => new TM::MapSphere (BaseURL => 'file:/tmp/'));
    ok ($md->isa ('TM::MapSphere::Dispatch') &&
	$md->isa ('TM::MapSphere'), 'dispatch: class ok');
    ok ($md->{mapspheres}->{'/'}->isa ('TM::MapSphere::MLDBM') &&
	keys %{$md->{mapspheres}} == 1, 'single sphere ok');
}

{ # test internal _find_longest_match
    my @ps = ('/', '/xxx/', '/yyy/xxx/', '/xxx/yyy/zzz/');
    is (TM::MapSphere::Dispatch::_find_longest_match ('/xxx/yyy/',         @ps), '/xxx/',         'longest match 1');
    is (TM::MapSphere::Dispatch::_find_longest_match ('/xxx/yyyz/',        @ps), '/xxx/',         'longest match 2');
    is (TM::MapSphere::Dispatch::_find_longest_match ('/xx/',              @ps), '/',             'longest match 3');
    is (TM::MapSphere::Dispatch::_find_longest_match ('/',                 @ps), '/',             'longest match 4');
    is (TM::MapSphere::Dispatch::_find_longest_match ('/xxx/yyy/zzz/aaa/', @ps), '/xxx/yyy/zzz/', 'longest match 5');
    eval {
	TM::MapSphere::Dispatch::_find_longest_match ('xxxx', @ps);
    }; like ($@, qr/no matching/, 'no path found');
}

{ # testing Mat::MapSpere a bit
    use TM::Materialized::MapSphere;
    eval {
	my $tm = new TM::Materialized::MapSphere (ms => []);
    }; ok ($@, 'faulty mapsphere');
    my $ms = new TM::MapSphere;
    eval {
	my $tm = new TM::Materialized::MapSphere (ms => $ms, url => 'rumsti');
    }; ok ($@, 'faulty URL');
    eval {
	my $tm = new TM::Materialized::MapSphere (ms => $ms, url => 'tm:/rumsti');
    }; ok ($@, 'faulty URL');

    my $tm = new TM::Materialized::MapSphere (ms => $ms, url => 'tm:/rumsti/');
    ok ($tm->isa ('TM'), 'proxy class');
}

{
    mkdir '/tmp/.ms1';
    mkdir '/tmp/.ms2';

    my $ms1 = new TM::MapSphere (BaseURL => 'file:/tmp/.ms1/');
    my $ms2 = new TM::MapSphere (BaseURL => 'file:/tmp/.ms2/');
    my $ms3 = new TM::MapSphere::Memory;
    my $md = new TM::MapSphere::Dispatch ('/'     => $ms1,
					  '/xxx/' => $ms2,
					  '/yyy/' => $ms3);
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (inline => 'xxx (yyy)
');
    $md->tao ('/rumsti/', $tm);

    ok ($ms1->tao ('/rumsti/'),    'map /rumsti/ must be in /');
    eval {
       $ms2->tao ('/rumsti/');
    }; like ($@, qr/unknown map/,  'map /rumsti/ not in /xxx/');

#    $md->clear;
#    ok (!$ms1->meta ('/rumsti/'),  'no rumsti in meta');
#    ok (!$ms2->meta ('/rumsti/'),  'no rumsti in meta');

    $md->tao ('/xxx/ramsti/', $tm);
    ok ($ms2->tao ('/ramsti/'), '/xxx/ramsti/: found /ramsti/ again');

    $md->tao ('/yyy/romsti/', $tm);
    ok ($ms3->tao ('/romsti/'), '/yyy/ramsti/: found /romsti/ again');


    $md->untao ('/yyy/romsti/');
    eval {
	$md->tao ('/yyy/romsti/');
    }; like ($@, qr/unknown/, 'romsti is gone');

    $md->untao ('/xxx/ramsti/');
    ok (-r '/tmp/.ms2/%2Framsti%2F', 'ramsti file itself here');
    eval {
	$md->tao ('/xxx/ramsti/');
    }; like ($@, qr/unknown/, 'ramsti is gone');

    unlink </tmp/.ms1/*>;
    unlink </tmp/.ms2/*>;
    rmdir  '/tmp/.ms1';
    rmdir  '/tmp/.ms2';
}


LOOP:
    foreach my $ms (
                    new TM::MapSphere::Memory, 
#		    new TM::MapSphere::MLDBM    (FileBase => 'file:/tmp/'),
#		    new TM::MapSphere::Dispatch ('/'      => new TM::MapSphere::Memory)
                    ) {
	my $c = ref ($ms);
	ok ($ms->isa ('TM::MapSphere'), "$c: class ok");
	
	{ # store a normal map there
	    use TM::Materialized::AsTMa;
	    my $tm = new TM::Materialized::AsTMa (inline => 'xxx (yyy)
');
	    my $t1 = Time::HiRes::time;
	    $ms->tao ('/rumsti/', $tm);
	    my $t2 = Time::HiRes::time;
	    
	    my $mm = $ms->meta ('/rumsti/');

##warn Dumper $mm;
	    ok ($t1 <= $mm->{created}  && $mm->{created}  <= $t2,               "$c: creation date ok");
	    ok ($t1 <= $mm->{modified} && $mm->{modified} <= $t2,               "$c: modified date ok");
	    
	    my %l = $ms->locations;
	    ok (eq_set ([keys   %l], [ '/rumsti/' ]),                           "$c: locations");
	    ok (eq_set ([values %l], [ 'TM::Materialized::AsTMa' ]) ||
		eq_set ([values %l], [ undef ]),                                "$c: locations");
	    
	    my $tm2 = $ms->tao ('/rumsti/');
	    ok ($tm2->isa ('TM::Materialized::AsTMa'),                          "$c: found /rumsti/ again");
	    ok ($tm2->{url} eq 'inline:xxx (yyy)
',                                                                              "$c: maps stored and retrieved");

	    eval {
		my $t = $ms->path ('/rumsti/yyy');                               # map not synced in, so it can't have it
		ok (0,                                                          "$c: toplet should not be there");
	    }; like ($@, qr/empty/,                                             "$c: got no toplet");
	    exit;
	    {
		# I probably should not refer to internals, here, but for testing it's ok?
		my $store = $ms->tao ('/rumsti/');
		ok ($store,                                                         "$c: store defined");
		my $nr = scalar keys %{$store->{assertions}};
		
		$ms->sync_in ('/rumsti/');                                          # this should propagate to the store
		
		$store = $ms->tao ('/rumsti/');
		ok ($nr < scalar keys %{$store->{assertions}},                      "$c: mapsphere sync increased assertions");
	    }

	    my $t = $ms->path ('/rumsti/yyy');                                  # now it should work
#warn "toplet rturned ".Dumper $t;
	    ok (ref ($t) eq 'Toplet',                                           "$c: got toplet");

	    # adding a second one, with meta data
	    $ms->tao ('/rumsti/ramsti/', $tm, { xxx => 'yyy' });

	    my %l2 = $ms->locations;
	    ok (eq_set ([keys %l2], [ '/rumsti/', '/rumsti/ramsti/' ]),         "$c: locations 2");

	    $mm = $ms->meta ('/rumsti/ramsti/');
	    ok ($mm->{xxx} eq 'yyy',                                            "$c: additional meta data (via tao)");
	    $ms->meta ('/rumsti/ramsti/', { aaa => 'bbb' });
	    $mm = $ms->meta ('/rumsti/ramsti/');
	    ok ($mm->{aaa} eq 'bbb',                                            "$c: additional meta data (via meta)");

	    $ms->untao ('/rumsti/');
	    ok ($ms->tao ('/rumsti/ramsti/'),                                   "$c: existing map found");
	    eval {
		$ms->tao ('/rumsti/');
	    }; like ($@, qr/unknown/,                                           "$c: deleted map not found");

	    {
		use TM::Materialized::AsTMa;
		my $tm    = new TM::Materialized::AsTMa (inline => 'aaa (bbb)
');
		$ms->tao  ('/ramsti/', $tm);
		$ms->meta ('/ramsti/', { sync_in => 1 });
		my $t = $ms->path ('/ramsti/aaa');
#warn "toplet returned ".Dumper $t;
		ok ($t->[TM->LID] eq 'tm://nirvana/aaa' &&
		    eq_array ( [ map { ref ($_) } @{$t->[TM->CHARS]} ],
			       [  ]),                                           "$c: ramsti path fetch");

	    }
	}

#	    next LOOP;

#    { # TODO check non-map objects
#    }

	{ # check T::M::MapSphere
	    use TM::Materialized::AsTMa;
	    my $tm    = new TM::Materialized::AsTMa (inline => 'aaa (bbb)
');
	    $ms->tao ('/remsti/', $tm);

	    use TM::Materialized::MapSphere;
	    my $vtm   = new TM::Materialized::MapSphere (ms  => $ms,
							 url => 'tm:/remsti/');

	    { # bad boy again, looking at internals
		my $store = $ms->tao ('/remsti/');
		my $nr    = scalar keys %{$store->{assertions}};
		$vtm->sync_in;
		ok ($vtm->is_a ('aaa', 'bbb'), 'vtm synced in');

#warn "vtm ".Dumper $vtm;
		$store = $ms->tao ('/remsti/');
		ok ($nr < scalar keys %{$store->{assertions}}, 'TM::Materialized::MapSphere: sync increased assertions remotely');
	    }

	    ok (!$vtm->is_a ('vvv', 'uuu'), 'local change, not');
	    my $tm3 = $ms->tao ('/remsti/');
	    ok (!$tm3->is_a ('vvv', 'uuu'), 'remote change, not');

	    $vtm->assert_maplets ([ undef, undef, 'isa', TM->KIND_ASSOC, [ 'class', 'instance' ], [ 'uuu', 'vvv' ]]);
#warn "vtm after uuu is ".Dumper $vtm;

	    ok ( $vtm->is_a ('vvv', 'uuu'), 'local change');
	    ok (!$tm3->is_a ('vvv', 'uuu') ||                            # the reason for this bizarre is that TM::Materialized::Memory uses SHARED memory,
                 $tm3->is_a ('vvv', 'uuu'), 'remote change, or not');    # so changes will be immediate, this may change in the future
	    $vtm->sync_out;
	    $tm3 = $ms->tao ('/remsti/');                                # have to refetch it
	    ok ( $tm3->is_a ('vvv', 'uuu'), 'remote change');
	}

	{ # testing clear
	    my %l = $ms->locations;
	    foreach (keys %l) {
		$ms->untao ($_);
	    }
	    eval {
		$ms->tao ('/rumsti/');
	    }; like ($@, qr/unknown map/, 'exception on non-existent map');
	}

    }

unlink </tmp/meta*>;

LOOP2:
    foreach my $ms (
		    new TM::MapSphere::Memory   (AutoList => 1),
		    new TM::MapSphere::MLDBM    (AutoList => 1, FileBase => 'file:/tmp/'),
		    new TM::MapSphere::Dispatch (AutoList => 1, '/'      => new TM::MapSphere::Memory),
		    ) {
	ok ($ms->{'AutoList'}, ref ($ms).': autolisting sticks');

	use TM::Materialized::AsTMa;
	my $tm    = new TM::Materialized::AsTMa (inline => 'aaa (bbb)
');
	$ms->tao ('/rumsti/',               $tm);
	$ms->tao ('/ramsti/rimsti/',        $tm);
	$ms->tao ('/ramsti/remsti/',        $tm);
	$ms->tao ('/ramsti/remsti/romsti/', $tm);

	my $toc = $ms->tao ('/ramsti/');                 # building table of contents

	ok ($toc->isa ('TM'), 'got map');
	ok ($toc->mids ('rimsti'), 'got entry 1');
	ok ($toc->mids ('remsti'), 'got entry 2');

	is (scalar $toc->maplets (type => 'isa', irole => 'instance', iplayer => 'rimsti'), 1, 'found map entry');
	is (scalar $toc->maplets (type => 'isa', irole => 'instance', iplayer => 'remsti'), 2, 'found map+collection entry');
    }

__END__





{ # testing Materialized mapsphere map
    my $ms = new TM::MapSphere ();

    use TM::Materialized::AsTMa;
    my $a  = new TM::Materialized::AsTMa (inline => 'xxx (yyy)
');
    $ms->tao (location => '/rumsti/', object => $a);                                    # NOTE: here we did not yet sync

warn "============= MS ==========".Dumper $ms;


}

__END__

