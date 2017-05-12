#!/usr/bin/perl -w

use Parallel::Simple::Dynamic;

my $tmpl   = 'AGCT' x 125;
my @list   = split( //, $tmpl );  # 500 single-character items

my $psd = Parallel::Simple::Dynamic->new();
#$psd->set_list(\@list);
#my $all_list = $psd->get_list();
#foreach $element (@$all_list) {print $element;}

#my @result = $psd->partition({parts => 4, list => \@list});
#foreach $element (@result) {print join(',',@$element), "\n";}

my @result = $psd->drun( { call_back => \&call_back, parts => 9, list => \@list } );

exit;

sub call_back {
	 my $pindex = shift( @_ );
	 foreach my $data ( @_ ) {
	 	print "Item( $pindex ): ", $data, "\n";
	
		sleep(1);
	 }					 
}

