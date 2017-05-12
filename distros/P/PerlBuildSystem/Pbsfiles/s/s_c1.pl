=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * 'x'

=back

=cut

#~ AddConfig 'a' => 'C1' ;
#~ AddConfig 'b' => 'C1' ;

PbsUse('Configs/gcc') ;
AddVariableDependency(a => 1) ;

AddRule 'dep', ['*/*.dep'], BuildOk("") ;
AddRule 'x', ['x' => '1'] ;
AddRule 'z', ['z' => '1'] ;


