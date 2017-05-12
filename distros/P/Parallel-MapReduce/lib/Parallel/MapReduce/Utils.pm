package Parallel::MapReduce::Utils;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT    = qw(Hchunk Hslice Hfetch Hstore chunk_n_store fetch_n_unchunk balance_keys);

use Data::Dumper;
use Storable qw(freeze thaw);
$Storable::Deparse = 1;
$Storable::Eval = 1;

# chunking a hash %H into chunks of size L
# size 'L' is more a rough estimate, than a hard limit

sub Hchunk {
    my $h = shift;
    my $L = shift;

    my @H;
    my $l = 0;
    my %hh = ();
    while (my ($k, $v) = each %$h) {
	my $ll = bytes::length(freeze(\ $v));
	if ($l + $ll > $L) {
	    push @H, { %hh } if keys %hh;
	    %hh = ();
	    $l = 0;
	}
	$hh{$k} = $v;
	$l += $ll;
    }
    push @H, { %hh } if keys %hh;
    return \@H;
}

sub chunk_n_store {
    my $memd   = shift;
    my $hash   = shift;
    my $prefix = shift;
    my $size   = shift || 1000;
    
    use Digest::MD5 qw(md5_hex);
    return
	map { $memd->set ( $_->[0], $_->[1]); $_->[0] }
        map { [ $prefix . md5_hex($_), $_ ] }
        map { freeze ($_) }
        @{ Hchunk ( $hash, $size) };
}

sub fetch_n_unchunk { #-- find mapper slice
    my $memd   = shift;
    my $chunks = shift;

    use Storable qw(thaw);
    return {
	map { %{ thaw ($_) }  }
        map { $memd->get ($_) }
        @$chunks
    };
}



# slicing hash %H into M slices (key-wise)

sub Hslice {
    my $h = shift;
    my $M = shift;

    my $H = {};    # will contain the result hash
    my $i = 0;
    map { $H->{ $i++ % $M }->{$_} = $h->{$_} } keys %$h;
    return $H;
}



sub Hstore {   # flush out hash onto memcacheds
    my $memd   = shift;
    my $hash   = shift;
    my $slice  = shift;
    my $job    = shift;

#     my @cs;
#     foreach my $k (keys %$hash) {
# 	$memd->set($prefix.$k, $hash->{$k});
# 	push @cs, $prefix.$k;
#     }
#     return @cs;

    return 
	map { $memd->set($_->[0], $_->[1] ); $_->[0] }
        map { [ $slice.$_, $hash->{$_} ]}
        keys %$hash;
}

sub Hfetch  {
    my $memd = shift;
    my $keys = shift;
    my $jobs  = shift;

#warn "Hfetch ".Dumper $keys;
    my $h = $memd->get_multi (@$keys);
#warn "fetched ".Dumper $h;

    my %h2;
    map { push @{ $h2{ $_->[0] } }, @{ $h->{ $_->[1] } } }  # aggregating all value lists
    map { $_ =~ /^(slice\d+:)(.+)/; [ $2, $_ ]}             # finding original keys
    keys %$h;
#warn "after aggregation ".Dumper \%h2;
    return \%h2;
}

sub fetch_n_consolidate  {
    my $memd = shift;
    my $keys = shift;

    my $h = $memd->get_multi (@$keys);
#warn "fetch_n ".Dumper $h;
    # resorting of different slices, but same keys
    my $h2;
    foreach my $k (keys %$h) {
	$k =~ /^\w+:(.+)/;
	push @{ $h2->{$1} }, @{ $h->{$k} };
    }
    return $h2;
}


sub balance_keys {
    my $keys = shift;
    my $job  = shift;
    my $N    = shift || 1;

    my %R;
    foreach my $r (@$keys) {
	$r =~ /^(slice\d+:)(.+)/;
	my $s = $2;     # find relevant part in key
	my $sum = 0;
	grep { $sum += $_ } map { ord ($_) } split //, $s ;        # convert critical part of key to hashed number
	push @{ $R{ $sum % $N } }, $r;                             # add the original key to some reducer
    }
    return \%R;
#warn "reducer distri ".Dumper \%R;
}





1;
