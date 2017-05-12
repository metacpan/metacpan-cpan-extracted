
use Test::Cookbook a => 1, b => 2 ; 

=head1 cookbook test

=head2 Simple usage

  my $cc_value = 'acc' ;
  print "CC = '$cc_value'\n" ;

Result:

=begin hidden

  my $expected_output = 'acc' ;
  is($cc_value, $expected_output, 'expected value') ;
  
  generate_pod("  CC = '$expected_output'\n\n") ;
  
  generate_pod('a test output') ;

=end hidden

=cut 
