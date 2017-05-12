use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::libscan
{
 my($self,$path) = @_;

 return '' 
	if($path =~ m:/(RCS|CVS|SCCS)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej|nfs)$:
	  );
 
 $path;
}

# check if we see DO_APACHE=1
my $dir = [];

if (grep {/^DO_APACHE=1$/i} @ARGV) {
	push @$dir, 'Apache';
}

# now clear out the ARGV list
@ARGV=();

# now tell them they can build mod_pml
unless (grep {/^Apache$/} @$dir) {
	print "You can build mod_pml also: perl Makefile.PL DO_APACHE=1\n";
}

WriteMakefile(
    'NAME'		=> 'PML',
    'VERSION_FROM' 	=> 'PML.pm', # finds $VERSION
    'EXE_FILES' 	=> [qw(bin/pml)],
    'DIR'		=> $dir,
);
