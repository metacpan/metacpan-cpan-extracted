
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * parent

=back

=cut

AddConfig OPTIMIZE_FLAG_1 => 'O4';
AddConfig OPTIMIZE_FLAG_1 => 'O3' ; 
AddConfig OPTIMIZE_FLAG_2 => 'O3' ;
AddConfig OPTIMIZE_FLAG_3 => 'xxx' ;
AddConfig UNDEF_FLAG => undef ;

AddRule '1', [ 'parent' => 'child'] ;

AddRule 'child',
	{
	  NODE_REGEX => 'child'
	, PBSFILE => './child.pl'
	, PACKAGE => 'child'
	#~ , COMMAND_LINE_DEFINITIONS => { OPTIMIZE_FLAG_3 => 'zzz'}
	} ;
