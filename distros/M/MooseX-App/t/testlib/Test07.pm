package Test07;
use MooseX::App::Simple qw(MutexGroup);

option 'UseAmmonia' => (
   is         => 'ro',
   isa        => 'Bool',
   mutexgroup => 'NonMixableCleaningChemicals',
);

option 'UseChlorine' => (
   is         => 'ro',
   isa        => 'Bool',
   mutexgroup => 'NonMixableCleaningChemicals'
);

has 'private_option' => (
   is      => 'ro',
   isa     => 'Int',
   default => 0,
);

sub run {
    print "ok";
}

1;
