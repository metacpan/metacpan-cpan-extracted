use strict;
use warnings;

use Test::More;
use Class::Inspector;

BEGIN{
    use_ok( 'DBIx::Skinny' );
    use_ok( 'Qudo::Driver::Skinny' );
    use_ok( 'Qudo::Driver::DBI' );
}

my $method_ds  = Class::Inspector->methods( 'DBIx::Skinny','public' );
my $method_qds = Class::Inspector->methods( 'Qudo::Driver::Skinny','public' );

push @{$method_ds} , _add_except_methods();

my @need_methods;
for my $method ( @{$method_qds} ){
    push @need_methods ,$method if ! grep {$_ eq $method} @{$method_ds};
}

can_ok('Qudo::Driver::DBI' , @need_methods);

done_testing();


sub _add_except_methods{
    my @more_except_methods = (
        qw/ attribute / 
    );

    return @more_except_methods;
}

