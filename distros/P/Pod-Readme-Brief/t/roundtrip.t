use strict; use warnings;

BEGIN { -f 'META.yml' or ( print "1..0 # SKIP running in a VCS checkout\n" ), exit }

use Pod::Readme::Brief;

sub slurp { open my $fh, '<', $_[0] or die "Could not open $_[0] to read: $!\n"; local $/; readline $fh }

my $src = slurp $INC{'Pod/Readme/Brief.pm'};

my $expected = slurp 'README';

my $got = Pod::Readme::Brief->new( split //, $src, -1 )->render( installer => 'eumm' );

my $diag = '';
my $ok = $expected eq $got ? 'ok' : do { ( $diag = $got ) =~ s/^/# /mg; 'not ok' };

print <<".";
1..1
$ok 1 - re-rendering own README yields identical results
$diag
.
