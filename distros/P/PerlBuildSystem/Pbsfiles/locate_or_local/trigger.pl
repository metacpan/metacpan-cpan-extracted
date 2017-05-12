=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * Y

=back

=cut

PbsUse 'Dependers/Locator' ;

AddRule 'Y',  ['*/Y' => LocateOrLocal('^./a$', './a'), 'x'] ;
AddRule 'z2', ['z2' => undef] ;

sub ExportTriggers
{
AddTrigger 'T3', ['subdir/Y' => 't'] ;

AddRule 'sub_trigger_Y',
	{
	  NODE_REGEX => '*/Y'
	, PBSFILE => './trigger.pl'
	, PACKAGE => 'Y'
	, BUILD_DIRECTORY => '/somwhere/'
	} ;
}


