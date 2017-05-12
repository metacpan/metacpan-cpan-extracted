# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

sub Table { map { [ split(' ', $_) ] } split(/\s*\n\s*/, shift) }

my @Errors = Table <<TABLE;
1.2     syntax 
1-2-3   syntax 
1,,2    syntax 
--      syntax 
abc     syntax 
2,1     order  
2-1     order  
3-4,1-2 order  
3,(-2   order  
2-),3   order  
(-),1   order  
TABLE


print "1..", 2 * @Errors, "\n";
Errors();


sub Errors
{
    print "#errors\n";
    my($error, $message);

    for $error (@Errors)
    {
	my($run_list, $expected) = @$error;

	eval { new Set::IntSpan $run_list };
	printf "#%-20s %-12s -> %s", "new Set::Intspan", $run_list, $@;
	$@ =~ /$expected/ or Not; OK;

	my $valid = valid Set::IntSpan $run_list;
	printf "#%-20s %-12s -> %s", "valid Set::Intspan", $run_list, $@;
	($valid or $@ !~ /$expected/) and Not; OK;
    }
}



