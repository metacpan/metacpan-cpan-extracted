use Pg::Loader::Misc;
use Test::More qw( no_plan );

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '' : 't/';


*ini_conf    = \& Pg::Loader::Misc::ini_conf;

my $h = { pgsql => { base => undef, host => 'localhost' },
          cvs1  => { null => 'na' } 
};

is_deeply ini_conf ( "${dir}data/tiny.conf"), $h;

__END__
