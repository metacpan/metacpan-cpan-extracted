package Test::Params; 

use strict; 
use warnings; 
use ModPerl::ParamBuilder; 

use base qw( ModPerl::ParamBuilder );

my $builder = ModPerl::ParamBuilder->new( __PACKAGE__ ); 

$builder->param( 'Testing' ); 

$builder->no_arg( 'Flagger' );
$builder->yes_no( 'Yessir' );
$builder->on_off( 'AutoCommit' );

$builder->param( { 
                   name    => 'SMTPServers', 
                   err     => 'SMTPServers xx.xx.xx.xx', 
                   take    => 'list',
                 });

$builder->param( {
                    name    => 'Foo',
                    take    => 'list',
                    key     => 'foo_data',
                });

$builder->load;

1;
