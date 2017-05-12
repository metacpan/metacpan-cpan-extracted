
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * all

=back

=cut

AddRule [VIRTUAL], 'all',   ['all' => 'z0', 'subdir/a', 'b', 'c'], BuildOk() ;

AddTrigger 'T1', ['X' => 'y', 'b', 'bb', 'z1'] ;
AddRule 'X',     ['X' => 'x', 'y', 'b', 'only_x'], "touch %FILE_TO_BUILD" ;
AddRule 'x',     ['x' => 'b'], "touch %FILE_TO_BUILD" ;

#~ AddRule [qr/'z0', 'subdir/a', 'b', 'c', 'y', 'b', 'only_x'], "touch %FILE_TO_BUILD" ;
AddRule 'build everything', [qr/(z0)|(subdir\/a)|b|c|y|b|(only_x)/ => undef], "touch %FILE_TO_BUILD" ;


ImportTriggers('./trigger.pl') ;
#~ ImportTriggers('./Pbsfiles/trigger/trigger.pl') ;
