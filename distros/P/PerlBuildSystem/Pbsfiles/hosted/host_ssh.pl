
use PBS::Shell::SSH ;

my $shell =  new PBS::Shell::SSH
		(
		  HOST_NAME        => '192.168.1.99'
		, USER_NAME        => 'nadim'
		#~ , PROTOCOL         => 1 # default is SSH2
		#~ , REUSE_CONNECTION => 1
		) ;

AddConfig  C_COMPILER_HOST => $shell ;
		
PbsUse('Rules/C') ;
PbsUse('Configs/gcc') ;

AddRule [VIRTUAL], 'all', ['*/all' => qw(world.o)], BuildOk() ;

AddRule '.o build shell', ['*/*.o'], undef, BuildShell($shell) ;


sub BuildShell
{
my $shell = shift || new PBS::Shell(USER_INFO => 'Test argument shell') ; # or find it in the config or whatever we please

return sub
	{
        my (
          $dependent_to_check
        , $config
        , $tree
        , $inserted_nodes
        ) = @_ ;
 	
	$tree->{__SHELL_OVERRIDE} = $shell ;
	$tree->{__SHELL_ORIGIN}   =  __FILE__ . __LINE__ ;
	}
}
