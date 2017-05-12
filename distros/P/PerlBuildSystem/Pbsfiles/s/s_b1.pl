=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * '*.lib'

=back

=cut

#~ LockConfigMerge() ;
#~ AddConfig 'a' => 'B1' ;

AddRule 'a', ['a' => 'a.dep'] ;
AddRule 'x', {NODE_REGEX =>'*.dep', PBSFILE => './Pbsfiles/s/s_c1.pl', PACKAGE => 'C1'} ;#, BUILD_DIRECTORY => '/bd_c1_b1/'} ;

