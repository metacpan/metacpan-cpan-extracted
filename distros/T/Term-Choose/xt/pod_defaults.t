use 5.10.0;
use strict;
use warnings;
use Test::More;
use List::Util qw( any );


my @long = qw( pad empty undef ll default max_cols max_height max_width keep no_spacebar mark footer skip_items margin );
my @simple = qw( alignment layout order clear_screen mouse beep hide_cursor index color codepage_mapping search ); # prompt
my @all = ( @long, @simple );
my @skip = qw( info prompt include_highlighted meta_items busy_string page tabs_prompt tabs_info );


plan tests => 2 + scalar @all;


my $file = 'lib/Term/Choose.pm';
my $fh;
my %option_default;

open $fh, '<', $file or die $!;
while ( my $line = <$fh> ) {
    if ( $line =~ /^sub _defaults \{/ .. $line =~ /^\}/ ) {
        if ( $line =~ m|^\s+#?\s*(\w+)\s+=>\s(\S+),| ) {
            my $op = $1;
            next if any { $op eq $_ } @skip;
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
    next if any { $key eq $_ } @skip;
    open $fh, '<', $file or die $!;
    while ( my $line = <$fh> ) {
        if ( $line =~ /^=head3\s\Q$key\E/ ... $line =~ /^=head/ ) { #head2
            chomp $line;
            next if $line =~ /^\s*\z/;
            push @{$pod{$key}}, $line;
        }
    }
    close $fh;
}

for my $key ( @simple ) {
    next if any { $key eq $_ } @skip;
    my $opt;
    for my $line ( @{$pod{$key}} ) {
        if ( $line =~ /(\d).*\(default\)/ || $line =~ /(\d) - default/ ) {
            $pod_default{$key} = $1;
            last;
        }
    }
}

for my $key ( @long ) {
    next if any { $key eq $_ } @skip;
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


is( scalar @all, scalar keys %option_default, 'scalar @all == scalar keys %option_default' );
is( scalar keys %pod_default, scalar keys %option_default, 'scalar keys %pod_default == scalar keys %option_default' );


for my $key ( sort keys %option_default ) {
    next if any { $key eq $_ } @skip;
    is( $option_default{$key}, $pod_default{$key}, "option $key: default value in pod matches default value in code" );
}
