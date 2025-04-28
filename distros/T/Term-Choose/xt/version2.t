use 5.10.1;
use strict;
use warnings;
use Time::Piece;
use Test::More;

my $v = -1;
my $v_pod = -1;
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
is( $v, $v_pod, 'Version in POD Term::Choose OK' );


my $lf_v_pod = -1;
open $fh, '<', 'lib/Term/Choose/LineFold.pm' or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^=pod/ .. $line =~ /^=cut/ ) {
        if ( $line =~ /^\s*Version\s+(\S+)/ ) {
            $lf_v_pod = $1;
        }
    }
}
close $fh;
is( $v, $lf_v_pod, 'Version in POD Term::Choose::LineFold OK' );


my @modules = qw(
lib/Term/Choose.pm
lib/Term/Choose/Constants.pm
lib/Term/Choose/LineFold.pm
lib/Term/Choose/LineFold/PP.pm
lib/Term/Choose/LineFold/PP/CharWidthAmbiguousWide.pm
lib/Term/Choose/LineFold/PP/CharWidthDefault.pm
lib/Term/Choose/Linux.pm
lib/Term/Choose/Opt/Mouse.pm
lib/Term/Choose/Opt/Search.pm
lib/Term/Choose/Opt/SkipItems.pm
lib/Term/Choose/Screen.pm
lib/Term/Choose/ValidateOptions.pm
lib/Term/Choose/Win32.pm
);
for my $module ( @modules ) {
    my $v_module = -1;
    open $fh, '<', $module or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^our\s\$VERSION\s=\s'(\d\.\d\d\d(?:_\d\d)?)';/ ) {
            $v_module = $1;
        }
    }
    close $fh;
    is( $v, $v_module, 'Version in $module OK' );
}



my $release_date = -1;
my $v_changes = -1;

open my $fh_ch, '<', 'Changes' or die $!;
while ( my $line = <$fh_ch> ) {
    if ( $line =~ /^\s*(\d+\.\d\d\d(?:_\d\d)?)\s+(\d\d\d\d-\d\d-\d\d)\s*\z/ ) {
        $v_changes = $1;
        $release_date = $2;
        last;
    }
}
close $fh_ch;
is( $v, $v_changes, 'Version in "Changes" OK' );



my $t = localtime;
my $today = $t->ymd;
is( $release_date, $today, 'Release date in Changes is date from today' );



done_testing();
