# this file is used to test the correct display of error message

#Test1
AddRule 'test1_1', ['1' => '2'], "touch %FILE_TO_BUILD" ;
AddRule 'test1_2', ['2' => '3'], BuildOk() ;
AddRule 'test1_3', ['3'], "touch %FILE_TO_BUILD" ;

#test2 
AddRule 'test2_3', ['3' => 4], "touch %FILE_TO_BUILD" ;

# bellow is error
AddSubpbsRule('test2_4', undef, "X.pl", "X") ;

# test 3, X.pl doesn't exist expect a nice error message when using -dsi -sfi -o
AddSubpbsRule('test3_4', '4', "X.pl", "X") ;

# test 4 multople subpbs
AddSubpbsRule('test4_4 again', '4', "X.pl", "X") ;
