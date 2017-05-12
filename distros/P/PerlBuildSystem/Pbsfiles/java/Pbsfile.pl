

#-------------------------------------------------------------------------------

ExcludeFromDigestGeneration('java-files' => qr/\.java$/);

#-------------------------------------------------------------------------------


my @classes = qw(HelloWorld.class) ;

AddRule [VIRTUAL], 'all', ['all' => @classes] => BuildOk() ;

AddRule 'classes', ['*/*.class' => '*.java']
    , 'javac -d %FILE_TO_BUILD_PATH %DEPENDENCY_LIST'; 

