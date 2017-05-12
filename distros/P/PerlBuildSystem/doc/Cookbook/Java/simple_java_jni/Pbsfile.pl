
use Data::TreeDumper;

PbsUse('Configs/Compilers/gcc') ;
#PbsUse('Rules/C') ;

AddConfigTo 'BuiltIn', 'CFLAGS_INCLUDE' => " -I $ENV{JDK_HOME}/include"
     . " -I $ENV{JDK_HOME}/include/linux" ;

ExcludeFromDigestGeneration('java-files' => qr/\.java$/);
ExcludeFromDigestGeneration('c-files' => qr/\.c$/);


my $shared_lib = 'libHelloWorldNative' ;
$shared_lib .= '.so' ; # should be platform independent

AddRule [VIRTUAL], 'all', ['all' => $shared_lib] => BuildOk() ;

AddRule 'manual c depender', ['*/*.c' => '*.h'] => BuildOk() ;

AddRule 'shared lib', [$shared_lib => 'HelloWorldNative.c']
	=> '%CC %DEPENDENCY_LIST -o %FILE_TO_BUILD -shared %CFLAGS_INCLUDE' ;

AddRule [CREATOR], 'java to header', ['*/*.h' => '*.class'] , \&myBuild;
  
AddRule 'classes', ['*/*.class' => '*.java']
    , 'javac -d %FILE_TO_BUILD_PATH %DEPENDENCY_LIST'; 
        

sub myBuild
{
	my ($config, $file_to_build, $dependencies) = @_ ;


    #print DumpTree($config);
    PrintDebug($file_to_build);
    print DumpTree($dependencies);
	
	return(1, "OK myBuild") ;
}
