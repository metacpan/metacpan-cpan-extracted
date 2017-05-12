use strict;
use warnings;
use Module::Build::Pluggable 'CPANfile';
use FindBin;

my $builder = Module::Build::Pluggable->new
  (module_name       => 'SQL::Concat'
   , dist_version_from   => 'lib/SQL/Concat.pm'
   , dist_author           => q{KOBAYASHI, Hiroaki <hkoba@cpan.org>},
   , license => 'perl'
   , meta_merge => {resources =>
		    {repository  =>
		     'https://github.com/hkoba/perl-SQL-Concat'
		     # NG: {url =>'https://github.com/hkoba/perl-SQL-Concat'}
		   }}
 );


$builder->create_build_script();
