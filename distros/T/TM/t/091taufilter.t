package Rumsti;

use TM;
use base qw(TM);
use Class::Trait ('TM::Synchronizable' => { exclude => 'mtime' } );

our $sync_in_called = 0;
our $sync_out_called = 0;

# I use this to reset the counters
sub reset {
    $sync_in_called = 0;
    $sync_out_called = 0;
}

sub mtime {
#warn "rumsti mtime";
    return time + 1; # always a change
}

sub source_in {
    $sync_in_called++;
# warn "sync_in_called $sync_in_called";
}

sub source_out {
    $sync_out_called++;
# warn "sync_out_called $sync_out_called";
}

1;

package Ramsti;

use TM::Tau::Filter;
use base qw(TM::Tau::Filter);

our $sync_in_called = 0;
our $sync_out_called = 0;

# I use this to reset the counters
sub reset {
    $sync_in_called = 0;
    $sync_out_called = 0;
}

sub source_out {
    $sync_out_called++;
# warn "Ramsti sync_out_called $sync_out_called";
}

1;

#-- test suite

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS =====================================================================

use TM;
require_ok ('TM::Tau::Filter');

eval {
    my $f = new TM::Tau::Filter (left => 1);
}; like ($@, qr/must be an instance/, 'left must be a TM instance');

{ # structural
    my $tm = new TM;
    my $f  = new TM::Tau::Filter (left => $tm);

    ok ($f->isa ('TM::Tau::Filter'),            'class');
    ok ($f->isa ('TM'),                         'superclass');
    ok ($f->does ('TM::ResourceAble'),          'trait: resource');
    ok ($f->does ('TM::Synchronizable'),        'trait: sync');
    is ($f->url, 'null:', 'default url');

    is ($f->left, $tm,                          'left operand');
}

{ # short chain
    my $f = new Ramsti (left => new Rumsti (url => 'in:whatever'), url => 'out:whatever');
    $f->left->reset;
    $f->reset;
    $f->sync_in;
    is ($Rumsti::sync_in_called,  1,         'Rumsti: tried sync in once');
    $f->sync_in;
    is ($Rumsti::sync_in_called,  2,         'Rumsti: tried sync in twice');
    $f->sync_out;
    is ($Rumsti::sync_out_called, 0,         'Rumsti: tried sync out never');
    is ($Ramsti::sync_out_called, 1,         'Ramsti: tried sync out once');
}

{ # longer chain
    my $f = new Ramsti (left => new Ramsti (left => new Rumsti (url => 'in:'),
					    url  => 'what:ever'),
			url => 'what:ever');
    $f->left->left->reset;
    $f->left->reset;
    $f->reset;
    $f->sync_in;
    is ($Rumsti::sync_in_called,  1,         'Rumsti: tried sync in once');
    $f->sync_in;
    is ($Rumsti::sync_in_called,  2,         'Rumsti: tried sync in twice');
    $f->sync_out;
    is ($Rumsti::sync_out_called, 0,         'Rumsti: tried sync out never');
    is ($Ramsti::sync_out_called, 1,         'Ramsti: tried sync out once');
}

{ # testing analysis filter

    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (inline => "aaa (bbb)\n");

    use TM::Tau::Filter::Analyze;

    my $bu = 'tm:';
    my $f = new TM::Tau::Filter::Analyze (left => $tm, baseuri => $bu);
    $f->sync_in;

    use Class::Trait;
    'TM::Analysis'->apply ($tm);
    my $stats = $tm->statistics ;                   # has to be here, as this is the time after parsing AsTMa

    ok (eq_set ([ $f->instances ($f->tids ('metric')) ],
		[ map { $bu . $_ } keys %$stats ]),                    'got all metrics');

    foreach my $t ( $f->instances ($f->tids ('metric')) ) {
	my ($v) = map { $_->[0] }
                       map { TM::get_players ($f, $_, $f->tids ('value')) }
                 	   $f->match_forall (type => $f->tids ('occurrence'), iplayer => $t);
	(my $k = $t) =~ s/^$bu//;
	is ($v, $stats->{$k}, "metric value: $t")
    }
}

#{ # testing QL filter
#}

__END__

{ # load ATM, 
  use File::Temp qw/ tempfile /;
  my ($fh, $filename) = tempfile( );
  print $fh "

aaa

bbb

";
  close ($fh);

  use File::stat;
  my $st = stat ($filename) or die "No $filename: $!";
  my $creation_time = $st->mtime;

  {
    my $tm = new TM (tau => "file:$filename");
    # default behavior:
    #   open file at start up
    ok ($tm->toplet ('aaa') && $tm->toplet ('bbb'), 'toplets loaded');

    #   allow changes
    {
      use TM::Transaction;
      my $tx = new TM::Transaction (map => $tm);
      is (ref ($tx), 'TM::Transaction', 'transaction ok');

      $tx->assert_toplet ($tx->id_toplet ('ggg'));
    } # transaction commit

    sleep 2;
    
  } # $tm goes out of scope, may try a sync
  
  # check:  do not write back
  $st = stat ($filename) or die "No $filename: $!";
  is ($creation_time, $st->mtime, 'waited a bit...file was not touched anymore');

  unlink $filename;
}


eval {
  require TM::Virtual::DNS;
  $TM::schemes{'dns:'} = 'TM::Virtual::DNS';
  my $tm = new TM (tau => 'dns:whatever');
  ok ($tm->toplet ('localhost'), 'dns: found localhost');
##print Dumper $localhost;
}; if ($@) {
  like ($@, qr/Can't locate/, "skipping DNS test ("._chomp($@).")");
}



