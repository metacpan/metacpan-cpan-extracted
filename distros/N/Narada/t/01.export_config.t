use lib 't'; use share; guard my $guard;

use Narada::Config qw( set_config get_config get_config_line get_db_config );

my @exports
    = qw( set_config get_config get_config_line get_db_config )
    ;
my @not_exports
    = qw( )
    ;

plan +(@exports + @not_exports)
    ? ( tests       => @exports + @not_exports                  )
    : ( skip_all    => q{This module doesn't export anything}   )
    ;

for my $export (@exports) {
    can_ok( __PACKAGE__, $export );
}

for my $not_export (@not_exports) {
    ok( ! __PACKAGE__->can($not_export) );
}
