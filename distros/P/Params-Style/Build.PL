# $Id: Build.PL,v 1.4 2005/10/18 09:41:04 mrodrigu Exp $
use Module::Build;

my $build= Module::Build->new
      ( module_name => 'Params::Style',
        license => 'perl',
        requires => { perl => '5.6.1',
                      Test::More          => 0.50,
                      Attribute::Handlers => 0.78,
                      Tie::Hash           => 0,
                    },
      );
$build->create_build_script;

