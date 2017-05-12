
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * 1

=back

=cut

AddRule '1>2', [ 1 => '2'] ;

AddRule 'subpbs 2',
	{
	  NODE_REGEX => '2'
	, PBSFILE => './2.pl'
	, PACKAGE => '2'
	} ;
	
	
