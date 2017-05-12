use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);

use constant SERVERS => ['127.0.0.1:11211'];

use Parallel::MapReduce::Utils;

my $online = 1 if $ENV{MR_ONLINE};

{
    my %H = (aaa => 'bbb', ccc => 'ddd', eee => 'fff', ggg => 'hhh');

    is_deeply(Hchunk (\%H, 1000), [
          {
            'eee' => 'fff',
            'ggg' => 'hhh',
            'aaa' => 'bbb',
            'ccc' => 'ddd'
          }
        ], 'Limit 1000');

    is_deeply(Hchunk (\%H, 40), [
            {
            'eee' => 'fff',
            'ggg' => 'hhh'
	    },
	    {
            'aaa' => 'bbb',
            'ccc' => 'ddd'
	    }
	], 'Limit 40');

    is_deeply(Hchunk (\%H, 30), [
 {
            'eee' => 'fff'
	    },
 {
            'ggg' => 'hhh'
	    },
 {
            'aaa' => 'bbb'
	    },
 {
            'ccc' => 'ddd'
	    }
	], 'Limit 30');
}

{
    my %H = (aaa => 'bbb', ccc => 'ddd', eee => 'fff', ggg => 'hhh');

sub _check {
    my $H = shift;
    my $N = shift;
    my $L = shift;
    my $h = Hslice ($H, $N);
    my $k;
    map { $k = (keys %{ $_ })[0]; is ($_->{$k}, $H{$k}, "$N data $k") } values %$h;

    is_deeply ([ sort keys %$h ], $L,          "$N bucket complete");
}

    _check (\%H, 1, [ 0 ]);
    _check (\%H, 2, [ 0, 1 ]);
    _check (\%H, 3, [ 0, 1, 2 ]);
    _check (\%H, 4, [ 0, 1, 2, 3 ]);
}

#-- chunked roundtrip over memcacheds

if ($online) {
    my $A = {1 => 'this is something ',
	     2 => 'this is something else',
	     3 => 'something else completely'};

    use Cache::Memcached;
    my $memd = new Cache::Memcached {'servers' => SERVERS, namespace => 'job1:' };

    foreach my $L  (10, 100, 1000) {
	my @cs = chunk_n_store ($memd, $A, 'ppp:', $L);
#	warn Dumper \@cs;
	my $B = fetch_n_unchunk ($memd, \@cs);
#	warn Dumper $B;
	is_deeply ($A, $B, 'roundtrip chunked');
    }
}

__END__

TODO

{ #-- store/fetch and reorder
    my $A = {1 => [ 'this is something ' ],
	     2 => [ 'this is something else' ] ,
	     3 => [ 'something else completely' ] };

    use Cache::Memcached;
    my $memd = new Cache::Memcached {'servers' => SERVERS, namespace => 'job1:' };

    my @cs = Hstore ($memd, $A, 'ppp:');
    warn Dumper \@cs;
    my $B = Hfetch ($memd, \@cs);
    warn Dumper $B;
    is_deeply ($A, $B, 'roundtrip store/fetch');

    push @cs, Hstore ($memd, $A, 'qqq:');
    warn Dumper \@cs;
    $B = Hfetch ($memd, \@cs);
    warn Dumper $B;

    map { is (scalar @{$_}, 2, 'fetch n: double mouble') }
    values %$B;
}


__END__

use_ok 'Hash::Tie::Memcached';

use constant SERVERS => ['127.0.0.1:11211'];

{
    my %hash;
    tie %hash, 'Hash::Tie::Memcached', prefix => 'aaa:', servers => SERVERS;

    $hash{xxx} = 'yyy';
    is ('yyy', $hash{'xxx'}, 'basic in/out');

    ok (exists $hash{'xxx'}, 'exist');
    ok (!exists $hash{'yyy'}, 'exists negative');

    $hash{bbb} = 'aaa';
    is ('aaa', $hash{'bbb'}, 'basic in/out');

    delete $hash{bbb};
    ok (!exists $hash{'bbb'}, 'exists negative');
    ok (exists $hash{'xxx'}, 'exist');

    untie %hash;
}

{
    my %hash;
    tie %hash, 'Hash::Tie::Memcached', prefix => 'aaa:', servers => SERVERS;
    is ('yyy', $hash{'xxx'}, 'new instance: basic in/out');
    ok (!exists $hash{'bbb'}, 'new instance: exists negative');
}

__END__


#join "," , each %hash;


warn "xxx exists" if $hash{xxx};


}
