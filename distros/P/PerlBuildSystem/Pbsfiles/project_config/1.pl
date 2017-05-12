
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * all

=back

=cut

PbsUse('Configs/CheckProjectConfig') ;

AddRule '1>2', [ 1 => '2'] ;

AddRule 'sub1>2',
	{
	  NODE_REGEX => '2'
	, PBSFILE => './dev/2.pl'
	, PACKAGE => '2'
	} ;
	