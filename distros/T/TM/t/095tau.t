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

sub synced {
  return [ $sync_in_called, $sync_out_called ];
}

sub source_in {
  my $self = shift;

#warn "rumsti source in $self";
  $sync_in_called++;
}

sub source_out {
#warn "rumsti source out $self";
  $sync_out_called++;
}

sub mtime {
#warn "Rumsti mtime + 1";
    return time + 1; # fake that we always have something new
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

sub synced {
    return [ $sync_in_called, $sync_out_called ];
}

sub source_out {
    $sync_out_called++;
}

1;

#-- test suite

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

# create tmp file
my @tmp;
use IO::File;
use POSIX qw(tmpnam);
for (0..1) {
    do { $tmp[$_] = tmpnam().".atm" ;  } until IO::File->new ($tmp[$_], O_RDWR|O_CREAT|O_EXCL);
}
##warn "tmp is $tmp";


END { unlink (@tmp) || die "cannot unlink '@tmp' file(s), but I am finished anyway"; }

sub _mk_file {
    my $file = shift;
    my $fh = IO::File->new ("> $file") || die "so what?";
    print $fh "
aaa (bbb)
bn: AAA

(ccc)
ddd: eee
fff: ggg
";
$fh->close;
}

_mk_file ($tmp[0]);

#close STDIN;
open (STDIN, $tmp[0]);

#== TESTS =====================================================================

require_ok ('TM::Tau');


{ # basic tests
    my $tm = new TM::Tau ('null: > null:', sync_in => 0, sync_out => 0);
#warn "============> ". ref ($tm->left) . " <-- left -- " . ref ($tm);
#    warn "this is it ".Dumper $tm;

    ok ($tm->isa ('TM::Tau'),              'class');
    ok ($tm->isa ('TM::Tau::Filter'),      'class');
    ok ($tm->isa ('TM'),                   'class');
    ok ($tm->does ('TM::Serializable::Dumper'), 'default: filter trait');

    ok ($tm->left->isa ('TM::Materialized::Null'),     'left null becomes a memory map');
}

{ # default
    my $tm = new TM::Tau (undef, sync_in => 0, sync_out => 0);
    ok ($tm->isa ('TM::Tau::Filter'),              'default: top level');
    ok ($tm->left->isa ('TM::Materialized::Null'), 'default: left');

    ok ($tm->does ('TM::Serializable::Dumper'), 'default: filter trait');

#    warn "this is it ".Dumper $tm;
}

eval { # errors
    my $tm = new TM::Tau ({});
}; like ($@, qr/undefined scheme/, _chomp ($@));

eval { # error
  my $tm = new TM::Tau ('rumsti:');
}; like ($@, qr/undefined scheme/, _chomp $@);

{ # test to override driver module
    my $tm = new TM::Tau ('ramsti: { Rumsti }', sync_in => 0, sync_out => 0);
    ok (ref ($tm->left) eq 'Rumsti',       'override: in special driver');

    { # test to override driver module
	eval {
	    my $tm = new TM::Tau ('> ramsti: { Rxxxumsti }');
	}; like ($@, qr/cannot load/, _chomp $@);
    }
}

{ # canonicalization trivia
    foreach my $s ('null:', '> null: <', '> null: >', '< null: >') {
	my $tm = new TM::Tau ($s, sync_in => 0, sync_out => 0);
	ok (1,                                          "canonical: parsing $s");
	ok ($tm->isa ('TM::Tau'),                       'canonical: class');
	ok ($tm->does ('TM::Serializable::Dumper'),     'canonical: filter trait');
	ok ($tm->left->isa ('TM::Materialized::Null'),  'canonical: left null becomes a memory map');
    }
}

{ # complex structure
    my $tm = new TM::Tau ('(null: * null: + null:) * (null:) > (null:)', sync_in => 0, sync_out => 0);

    ok ($tm->isa ('TM::Tau'),                                          'top level');
    ok ($tm->does ('TM::Serializable::Dumper'),                        'top level does');

    ok ($tm->left->isa ('TM::Tau::Filter'),                            'second level');

    ok ($tm->left->left->isa ('TM::Tau::Federate'),                    'third level');

    ok ($tm->left->left->right->isa ('TM::Materialized::Null'),        'federate right level');
    ok ($tm->left->left->left->isa  ('TM::Tau::Filter'),               'federate left level');

    ok ($tm->left->left->left->left->isa  ('TM::Materialized::Null'),  'federate left left level');
}

#-- synchronisation manual ----------------------------------

# avoid being bothered by STDOUT
close STDOUT;
open STDOUT, ">$tmp[1]";


#-- sync automatic

use TM::Tau;
{ # testing events
    $TM::Tau::sources{'rumsti:'} = 'Rumsti';
    $TM::Tau::filters{'rumsti:'} = 'Ramsti';

    my $tests = {
 	'01 rumsti: > rumsti:'      => { uc => [ 1, 0 ],
					 ac => [ 0, 0 ], debug => 0,
					 ud => [ 1, 0 ],
					 ad => [ 0, 1 ] },
	
 	'02 rumsti:'                => { uc => [ 1, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 1, 0 ],
					 ad => [ 0, 0 ] },

   	'03 rumsti: >'              => { uc => [ 1, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 1, 0 ],
					 ad => [ 0, 0 ] },

  	'04 > rumsti:'              => { uc => [ 0, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 0, 0 ],
					 ad => [ 0, 1 ] },

  	'05 > rumsti: <'            => { uc => [ 1, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 1, 0 ],
					 ad => [ 0, 0 ] },

   	'06 > rumsti: >'            => { uc => [ 1, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 1, 0 ],
					 ad => [ 0, 1 ] },

   	'07 < rumsti: <'            => { uc => [ 0, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 0, 0 ],
					 ad => [ 0, 0 ] },

  	'08 < rumsti: >'            => { uc => [ 0, 0 ],
					 ac => [ 0, 0 ],
					 ud => [ 0, 0 ],
					 ad => [ 0, 1 ] },

    };

    foreach my $t (sort { $a cmp $b } keys %$tests) {
	Rumsti::reset;
	Ramsti::reset;
#	  next unless $t =~ /02/;
	  (my $tau = $t) =~ s/\d+\s*//;
        {
	    my $tm = new TM::Tau ($tau);

#warn Dumper [ $tm->does ('TM::Serializable::AsTMa') ]; exit;
#warn Dumper $tm;
#warn "============> ". ref ($tm->left) . " <-- left -- " . ref ($tm);
#warn "test $tau";
#warn Dumper $tm if $tests->{$t}->{debug};      

#    warn "synced after create ".Dumper Rumsti::synced;
	    ok (eq_array ($tests->{$t}->{uc}, Rumsti::synced), "$tau : rumsti after creation");
	    ok (eq_array ($tests->{$t}->{ac}, Ramsti::synced), "$tau : ramsti after creation");
#warn "Ramsti after create ".Dumper Ramsti::synced;

            $tm->internalize ('remsti'); # do something with the map, so that the timestamp is modified

	}
#warn "Rumsti synced after destruct ".Dumper Rumsti::synced;
#warn "Ramsti after decon ".Dumper Ramsti::synced;
	ok (eq_array ($tests->{$t}->{ud}, Rumsti::synced), "$tau : rumsti after deconstruction");
	ok (eq_array ($tests->{$t}->{ad}, Ramsti::synced), "$tau : ramsti after deconstruction");
    }
}

{ # test with +
    foreach my $i (1..4) {
	Rumsti::reset;
	  {
	      my $tm = new TM::Tau ('('. join (" + ", ('rumsti:') x $i). ' ) > -');

#warn "============> ". ref ($tm->left) . " <-- left -- " . ref ($tm);
	  }
#warn Dumper Rumsti::synced;
	  ok (eq_array (Rumsti::synced,	[ $i, 0 ]), "$i: federated sync in/out");
    }
}

{ # testing auto registration of filters
    eval {
	my $tm = new TM::Tau ('null: * http://psi.tm.bond.edu.au/queries/1.0/analyze');
    }; like ($@, qr/undefined scheme/, 'auto reg: '._chomp ($@));

    {
	eval "use TM::Tau::Filter::Analyze;"; # we do it to postpone the loading
	my $tm = new TM::Tau ('null: * http://psi.tm.bond.edu.au/queries/1.0/analyze');
    }; 
    ok (1, 'auto reg: detected');
}

foreach my $tau ('io:stdin > io:stdout', 'io:stdin > -', '- > -', '- > io:stdout') { # testing stdin and stdout
    # redirect all to the file
    open STDOUT, ">$tmp[1]";
    {
	my $tm = new TM::Tau ($tau);
#warn Dumper $tm;
    }

    my $fh = IO::File->new ($tmp[1]) || die "cannot reopen what I just wrote";
    local $/ = undef;
    my $s = <$fh>;
    close $fh;
#    warn $s;

    like ($s, qr/\$tm = bless/, "$tau: dumper found");
    {
	my $tm;
	eval $s; # Perl is so sick :-)
	ok ($tm->isa ('TM'), "$tau: map found");
	ok ($tm->tids ('thing'), "map has things");
    }
}

__END__



__END__

