use 5.010000;
use strict;
use warnings;
no if $] >= 5.018, warnings => "experimental::smartmatch";
use Test::More;


my @long = ( qw( pad pad_one_row empty undef ll default max_height max_width lf keep no_spacebar mark ) );
my @simple = ( qw( justify layout order clear_screen page mouse beep hide_cursor index ) ); # prompt
my @all = ( @long, @simple );
my @deprecated = ( qw() );


plan tests => 2 + scalar @all;


my $file = 'lib/Term/Choose.pm';
my $fh;
my %option_default;

open $fh, '<', $file or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^sub __defaults \{/ .. $line =~ /^\}/ ) {
        if ( $line =~ m|^\s+#?\s*(\w+)\s+=>\s(\S+),| ) {
            my $op = $1;
            next if $op eq 'prompt';
            next if $op ~~ @deprecated;
            $option_default{$op} = $2;
            $option_default{$op} =~ s/^undef\z/undefined/;
            $option_default{$op} =~ s/^["']([^'"]+)["']\z/$1/;
         }
    }
}
close $fh;


my %pod_default;
my %pod;

for my $key ( @all ) {
    next if $key ~~ @deprecated;
    open $fh, '<', $file or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^=head2\s\Q$key\E/ ... $line =~ /^=head/ ) {
            chomp $line;
            next if $line =~ /^\s*\z/;
            push @{$pod{$key}}, $line;
        }
    }
    close $fh;
}

for my $key ( @simple ) {
    next if $key ~~ @deprecated;
    my $opt;
    for my $line ( @{$pod{$key}} ) {
        if ( $line =~ /(\d).*\(default\)/ ) {
            $pod_default{$key} = $1;
            last;
        }
    }
}

for my $key ( @long ) {
    next if $key ~~ @deprecated;
    if ( $key eq 'pad_one_row' ) {
        for my $line ( @{$pod{$key}} ) {
            if ( $line =~ /default:\s([^)]+)\)/ ) {
                $pod_default{$key} = $1;
                last;
            }
        }
    }
    else {
        for my $line ( @{$pod{$key}} ) {
            if ( $line =~ /default:\s["']([^'"]+)["'](?:\)|\s*)/ ) {
                $pod_default{$key} = $1;
                last;
            }
            if ( $line =~ /default:\s(\w+)(?:\)|\s*)/ ) {
                $pod_default{$key} = $1;
                last;
            }
        }
    }
}


is( scalar @all, scalar keys %option_default, 'scalar @all == scalar keys %option_default' );
is( scalar keys %pod_default, scalar keys %option_default, 'scalar keys %pod_default == scalar keys %option_default' );


for my $key ( sort keys %option_default ) {
    next if $key ~~ @deprecated;
    if ( $key eq 'pad_one_row' ) {
        my $por = 0;
        if ( $pod_default{$key} eq 'value of the option I<pad>' ) {
            $por = 1;
        }
        is( $por, '1', "option $key: default value in pod OK" );
    }
    else {
        is( $option_default{$key}, $pod_default{$key}, "option $key: default value in pod matches default value in code" );
    }
}
