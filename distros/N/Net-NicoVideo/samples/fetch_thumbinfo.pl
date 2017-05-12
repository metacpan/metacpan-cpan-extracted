#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/say/;

use Net::NicoVideo;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $video_id = $ARGV[0] or die "usage: $0 video_id \n";

my $nnv = Net::NicoVideo->new;

my $info = $nnv->fetch_thumbinfo($video_id);

for ( sort $info->members ){
    my $val = $info->$_();

    print_val($_, $val, 0);
}

sub print_val {
    my $label   = shift;
    my $val     = shift;
    my $indent  = shift || 0;
    my $pad     = '  ' x $indent++;
    if( ref $val eq 'ARRAY' ){
        say $pad . "$label: \@";
        for my $item ( @$val ){
            print_val( '- ', $item, $indent );
        }    
    }elsif( ref $val eq 'HASH' ){
        say $pad . "$label: \%";
        for my $k ( keys %$val ){
            print_val( "$k =>", $val->{$k}, $indent );
        }
    }else{
        say $pad . "$label: " . $val;
    }
}


1;
__END__
