
package test::shared ;

  $VAR = 'foovar' ;
  
  my $calls ;

##########
# METHOD #
##########

sub method {
  ++$calls ;
  my $v = eval('$main::TEST');
  print "SHARED[$calls]! [$main::TEST][$v] <<@_>>\n" ;
}

1;

