use strict;
use ExtUtils::MakeMaker;

my %opts = 
  (
   NAME => 'POE::XS::Queue::Array',
   VERSION_FROM => 'Array.pm',
   OBJECT => 'Array.o queue.o alloc.o',
   PREREQ_PM => {
		 'POE'    => 0.29,
		},
  );
my $eu_mmv = eval $ExtUtils::MakeMaker::VERSION;
if ($eu_mmv > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tonyc@cpan.org>';
  $opts{ABSTRACT} = 'XS version of POE::Queue::Array';
}
if ($eu_mmv > 6.30) {
  $opts{LICENSE} = 'perl';
}

WriteMakefile(%opts);


