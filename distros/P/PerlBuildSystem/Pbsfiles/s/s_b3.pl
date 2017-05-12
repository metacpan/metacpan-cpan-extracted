=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * '*.lib'

=back

=cut

AddConfig 'a' => 'B3' ;

AddRule 'c', ['*/c' => 'c.dep'] ;
AddRule 'x', 
	{
	  NODE_REGEX =>'*.dep'
	, PBSFILE => './Pbsfiles/s/s_c1.pl'
	, PACKAGE => 'C1'
	, BUILD_DIRECTORY => '/xxx/'
	#~ , DEBUG_DISPLAY_DEPENDENCIES => undef
	} ;
