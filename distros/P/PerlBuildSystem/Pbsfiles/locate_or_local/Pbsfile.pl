
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * all

=back

=cut

PbsUse 'Dependers/Locator' ;

AddRule [VIRTUAL], 'all',  ['all' => 'a', 'b', 't'] ;

AddRule 't1',  ['t' => 'cc'] ;
AddRule 't2',  ['t' => 'z2'] ;

AddTrigger 'T1', ['t/1' => 't'] ;
AddTrigger 'T2', ['t/2' => 't'] ;

AddRule '1',  ['*/1' => 'x', 'y', 'b', LocateOrLocal('^./a$', './a')] ;

AddRule '2',  ['*/2' => 'x2', 'y'] ;
	

ImportTriggers('./trigger.pl') ;


