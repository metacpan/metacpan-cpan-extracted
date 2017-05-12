#The installing ,by now,is too simple to use the standart way.
#just copy the module to its place:

print "In which directory you me to install?\n";
my $c=0;
for my $dir(@INC)
{
    print $c.'] ';
    print $dir,"\n";
    $c++;
}

my $dir=<STDIN>;
mkdir("$INC[$dir]/Bio",'0666') if(!-d "$INC[$dir]/Bio");
mkdir("$INC[$dir]/Bio/SABio",'0666') if(!-d "$INC[$dir]/Bio/SABio");
open(F,"NCBI.pm") or die "Can't find the module file!\n" ;
@f=<F>;
close F;
open(F,">$INC[$dir]/Bio/SABio/NCBI.pm") or die "Can't copy the file to destination directory $INC[$dir]/Bio/SABio/NCBI.pm!\n";
print F @f;
close F;
print "Installed!\n";
# use ExtUtils::MakeMaker;
# # See lib/ExtUtils/MakeMaker.pm for details of how to influence
# # the contents of the Makefile that is written.
# WriteMakefile(
#     'NAME'		=> 'Bio::SABio::NCBI',
#     'VERSION_FROM'	=> 'NCBI.pm', # finds $VERSION
#     'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
#     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
#       (ABSTRACT_FROM => 'NCBI.pm', # retrieve abstract from module
#        AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
# );
