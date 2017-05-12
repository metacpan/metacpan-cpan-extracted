BEGIN {
    if ( $] >= 5.010 ) {
        print "Perl-5.10+ has built-in named captures. Please don't use this module.\n";
        exit 0;
    }
}
use Module::Build;
Module::Build->new
(
   license => 'perl',
   create_readmore => 'Do it now. Do it harder.',
   dist_author => '"Josh ben Jore" <jjore@cpan.org>',

   module_name => 'Regexp::NamedCaptures',
   requires => {
                # This stuff comes with perl anyway.
                strict => 0,
                warnings => 0,
                Carp => 0,
                perl => '5.7.1',
                
                'Text::Balanced' => 0,
               },
   recommends => {
                  'Params::Validate' => 0,
                 },
)->create_build_script();
   
