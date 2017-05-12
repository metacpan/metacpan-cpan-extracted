use 5.010000;
use strict;
use warnings;
use Time::Piece;
use Test::More tests => 6;



my $v             = -1;
my $v_pod         = -1;
my $v_linux       = -1;
#my $v_pod_linux   = -1;
my $v_win32       = -1;
#my $v_pod_win32   = -1;
my $v_const       = -1;
my $v_changes     = -1;
my $release_date  = -1;


open my $fh, '<', 'lib/Term/Choose.pm' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^our\s\$VERSION\s=\s'(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v = $1;
    }
    if ( $line =~ /^=pod/ .. $line =~ /^=cut/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $v_pod = $1;
        }
    }
}
close $fh;

open $fh, '<', 'lib/Term/Choose/Linux.pm' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^our\s\$VERSION\s=\s'(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_linux = $1;
    }
#    if ( $line =~ /^=pod/ .. $line =~ /^=cut/ ) {
#        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
#            $v_pod_linux = $1;
#        }
#    }
}
close $fh;

open $fh, '<', 'lib/Term/Choose/Win32.pm' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^our\s\$VERSION\s=\s'(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_win32 = $1;
    }
#    if ( $line =~ /^=pod/ .. $line =~ /^=cut/ ) {
#        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
#            $v_pod_win32 = $1;
#        }
#    }
}
close $fh;

open $fh, '<', 'lib/Term/Choose/Constants.pm' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^our\s\$VERSION\s=\s'(\d\.\d\d\d(?:_\d\d)?)';/ ) {
        $v_const = $1;
    }
#    if ( $line =~ /^=pod/ .. $line =~ /^=cut/ ) {
#        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
#            $v_pod_const = $1;
#        }
#    }
}
close $fh;

open my $fh_ch, '<', 'Changes' or die $!;
while ( my $line = <$fh_ch> ) {
    if ( $line =~ /^\s*(\d+\.\d\d\d(?:_\d\d)?)\s+(\d\d\d\d-\d\d-\d\d)\s*\z/ ) {
        $v_changes = $1;
        $release_date = $2;
        last;
    }
}
close $fh_ch;


my $t = localtime;
my $today = $t->ymd;


is( $v,            $v_pod,         'Version in POD Term::Choose OK' );
is( $v,            $v_linux,       'Version in Term::Choose::Linux OK' );
is( $v,            $v_win32,       'Version in Term::Choose::Win32 OK' );
is( $v,            $v_const,       'Version in Term::Choose::Constants OK' );
#is( $v,            $v_pod_linux,   'Version in POD Term::Choose::Linux OK' );
#is( $v,            $v_pod_win32,   'Version in POD Term::Choose::Win32 OK' );
is( $v,            $v_changes,     'Version in "Changes" OK' );
is( $release_date, $today,         'Release date in Changes is date from today' );
