
# pbs should support 'FORCED' node even in warp modes

AddRule 'a', ['a' => 'b'], "touch %FILE_TO_BUILD" ;
AddRule 'b', ['b' => 'c'], "touch %FILE_TO_BUILD" ;
AddRule 'c', ['c'], "touch %FILE_TO_BUILD" ;
AddRule [FORCED, VIRTUAL], 'test', ['test' => 'a'], "echo testing" ;

