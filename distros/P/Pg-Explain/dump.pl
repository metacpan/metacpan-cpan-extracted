#!/usr/bin/perl
use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use Pg::Explain;
use Data::Dumper;
use Getopt::Long;
$Data::Dumper::Indent = 1;

$Data::Dumper::Sortkeys = sub {
    my $input = shift;
    return [
        sort {
            my $va = $input->{ $a };
            my $vb = $input->{ $b };
            return -1 if ( '' eq ref( $va ) ) && ( '' ne ref( $vb ) );
            return 1  if ( '' ne ref( $va ) ) && ( '' eq ref( $vb ) );
            return $a cmp $b;
        } keys %{ $input }
    ];
};
my $text = 0;

GetOptions( 'text' => \$text ) or die( "Syntax:\n    $0 [-t] plan_file\n\nBy default it dumps data structure for the explain.\nWith -t option, it will print textual representation of it.\n" );

my $explain = Pg::Explain->new( 'source_file' => shift );

if ( $text ) {
    print $explain->as_text();
}
else {
    my $dumped = Dumper( $explain->get_struct() );
    $dumped =~ s/ \A \$VAR1 \s+ = \s+ //xms;
    $dumped =~ s/ \} ; \s* \z /}\n/xms;
    print $dumped;
}
