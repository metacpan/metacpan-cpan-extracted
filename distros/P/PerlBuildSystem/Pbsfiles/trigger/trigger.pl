=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * Y

=back

=cut

AddRule 'Y',  ['Y' => 'subdir/a', 'x', 'y', 'z2', 'not_root'], "touch %FILE_TO_BUILD" ;
AddRule [VIRTUAL], 'z2', ['z2' => undef], BuildOk("done") ;

AddRule 'build everything', [qr/(subdir\/a)|x|y|(not_root)/ => undef], "touch %FILE_TO_BUILD" ;

sub ExportTriggers
{
AddTrigger 'T2', ['Y' => 'z2', 'z0'] ;
AddRule 'sub_trigger_Y',
	{
	  NODE_REGEX => 'Y'
	, PBSFILE => './trigger.pl'
	, PACKAGE => 'Y'
	, BUILD_DIRECTORY => 'somwhere/'
	} ;
}


