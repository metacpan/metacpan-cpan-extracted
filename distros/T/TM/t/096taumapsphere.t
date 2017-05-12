#------------------------------------------------------------------------------------------------
# build a 'persistent' mapsphere (persistent is over invocations here)

package MyMapSphere;

use TM::Tau::Filter;
use base qw(TM::Tau::Filter);
use Class::Trait qw(TM::MapSphere);

sub source_in {
    my $self = shift;

#warn "MyMapSphere source in";
    $self->{left}->source_in;
    die unless $self->{_path_to_be}; # just make sure its there
    $self->mount (delete $self->{_path_to_be}, $self->{left});
#warn "mount done";
}

sub mtime {
    return time + 1; # here we also are very eager to do things
}

1;

package MyPersistentMapSphereFilter;

our $ms = new MyMapSphere (baseuri => 'tm:');

sub new {
    my $class = shift; # we do not really care about that one
    my %opts  = @_;
#warn "got URL $opts{url}";
    (my $path = $opts{url}) =~ s/^tm://;
    $ms->{_path_to_be} = $path; # !!! NB: Here I _know_ that I am the only one fiddling around, this is NOT thread-safe!!
    return $ms;
}

1;

package MyPersistentMapSphere;

sub new {
    my $class = shift; # dont care
    my %opts  = @_;
#warn "new got URL $opts{url}";
    (my $path = $opts{url}) =~ s/^tm://;
#warn "got path $path";
    return $MyPersistentMapSphereFilter::ms->is_mounted ($path);
}

1;


use strict;
use warnings;

#use Class::Trait 'debug';

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

#-- doing something with maps, preparations

my ($tmp1, $tmp2);
use IO::File;
use POSIX qw(tmpnam);
do { $tmp1 = tmpnam() . '.atm' ;  } until IO::File->new ($tmp1, O_RDWR|O_CREAT|O_EXCL);
do { $tmp2 = tmpnam() ;           } until IO::File->new ($tmp2, O_RDWR|O_CREAT|O_EXCL);

END { unlink ($tmp1, $tmp2) || warn "cannot unlink tmp files '$tmp1' and '$tmp2'"; }

tmpmap ('
aaa is-a bbb

ccc is-a bbb

(zzz)
xxx: aaa
yyy: ccc
');

sub tmpmap {
    my $astma = shift;
    my $fh = IO::File->new ("> $tmp1") || die "so what?";
    print $fh $astma."\n";
    $fh->close;
}

sub tmpres {
    my $fh = IO::File->new ($tmp2) || die "cannot reopen what I just wrote";
    local $/ = undef;
    my $s = <$fh>;
    close $fh;
    # now make sure we have something different there
    $fh = IO::File->new (">$tmp2") || die "cannot reopen for rewriting";
    print $fh "xxx";
    close $fh;
    return $s;
}

#== TESTS =====================================================================

use TM::Tau;
$TM::Tau::filters{'^tm:/.*'} = 'MyPersistentMapSphereFilter';
$TM::Tau::sources{'^tm:/.*'} = 'MyPersistentMapSphere';

{ # add a first map, right hand side
    my $t = new TM::Tau ("file:$tmp1 > tm:/rumsti/");
}

ok ($MyPersistentMapSphereFilter::ms->tids ('rumsti'),                       'mem persistent mapsphere: map has been mounted');
ok ($MyPersistentMapSphereFilter::ms->is_mounted ('/rumsti/')->tids ('aaa'), 'mem persistent mapsphere: map has values');

for (0..5) { # stress testing: adding, retracting, re-adding, all right-hand side

    { # add another
	new TM::Tau ("file:$tmp1 > tm:/ramsti/");
    }

    ok ($MyPersistentMapSphereFilter::ms->tids ('rumsti'),                       'mem persistent mapsphere: map still mounted');
    ok ($MyPersistentMapSphereFilter::ms->is_mounted ('/rumsti/')->tids ('aaa'), 'mem persistent mapsphere: map has still values');
    ok ($MyPersistentMapSphereFilter::ms->tids ('ramsti'),                       'mem persistent mapsphere: new map mounted');
    ok ($MyPersistentMapSphereFilter::ms->is_mounted ('/ramsti/')->tids ('aaa'), 'mem persistent mapsphere: new map has values');
    
#warn Dumper $MyPersistentMapSphereFilter::ms;
    $MyPersistentMapSphereFilter::ms->umount ('/ramsti/');
}


for (0..5) {
    { # left-hand side also
	new TM::Tau ("tm:/rumsti/ > tm:/remsti/");
    }

    ok ($MyPersistentMapSphereFilter::ms->tids ('remsti'),                       'mem persistent mapsphere: copied map mounted');
    ok ($MyPersistentMapSphereFilter::ms->is_mounted ('/remsti/')->tids ('aaa'), 'mem persistent mapsphere: copied map has values');

    $MyPersistentMapSphereFilter::ms->umount ('/remsti/');
}


__END__

{ # test mapsphere
    my $tm = new TM::Tau ("file:$tmp > tm:/test/");
    $tm->{map}->sync_out;

    like ($tm->{mapsphere}->{maps}->{'/test/'}->tids ('aaa'), qr/aaa$/, 'map established in mapsphere');
}

