use strict;
use warnings;

$ENV{LC_ALL} = 'C';  # Enforce consistent sort() results for tests.

sub get_abslib {
    use FindBin qw[$Bin];
    my $relbin = $Bin;
    return "$relbin/lib";
}

sub get_rellib {
    use FindBin qw[$Bin];
    use Cwd qw[getcwd];
    my $relbin = $Bin;
    substr($relbin, 0, length(getcwd()) + 1) = '';
    return "$relbin/lib";
}

sub get_xref {
    my ($xref_opt) = @_;
    $xref_opt //= {};
    my $lib;
    if (defined $xref_opt->{incdir}) {
        $lib = delete $xref_opt->{incdir};
        delete $xref_opt->{abslib};
    } else {
        $lib = delete $xref_opt->{abslib} ? get_abslib() : get_rellib();
    }
    $lib = [ $lib ] unless ref $lib;
    $lib = [ grep { -d } @{ $lib } ];
    $xref_opt->{INC} //= $lib;
    $xref_opt->{__allow_relative} = 1;
    my $xref = PPI::Xref->new($xref_opt);
    is_deeply($xref->INC, $lib, "test lib set");
    return ($xref, ref $lib ? $lib->[0] : $lib, $lib);
}

sub warner {
    $@ = shift;
    chomp($@);
    print "# warning: $@\n";
}

sub cachefile_sanity {
  my ($xref, $cachefile, $cache_directory) = @_;
  ok(-s $cachefile, "non-empty cachefile exists");
  like($cachefile, qr/\.cache$/, "cachefile ends in .cache");
  like($cachefile, qr/\Q$cache_directory\E/,
       "cachefile path contains the cache directory");
  $xref->looks_like_cache_file($cachefile);
}

1;
