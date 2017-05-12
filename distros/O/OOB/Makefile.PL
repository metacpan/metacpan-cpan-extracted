require 5.005; # Test::More doesn't support earlier
use ExtUtils::MakeMaker;
eval "use Devel::Required";

# remove / install warnings
open FILE, '<lib/OOB.pm'
  or die "Could not open lib/OOB.pm for reading: $!";
my $OOB = do { local $/; <FILE> };
$] < 5.006
  ? $OOB =~ s/use warnings/#use warnings/s
  : $OOB =~ s/#use warnings/use warnings/s;
close FILE;

# install file again
open FILE, '>lib/OOB.pm'
  or die "Could not open lib/OOB.pm for writing: $!";
print FILE $OOB;
close FILE;

WriteMakefile (
 NAME		=> "OOB",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'out of band data for any data structure in Perl',
 VERSION_FROM	=> 'lib/OOB.pm',
 PREREQ_PM	=> { qw(
                    Scalar::Util  1.14
                    Sub::Identify 0.02
                   ) },
);
