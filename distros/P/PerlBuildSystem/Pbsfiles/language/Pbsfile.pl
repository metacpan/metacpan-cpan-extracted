
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * all

=back

=cut

#~ PbsUse 'Language/Simplified' ;

#~ AddRule 't0', ['all'] ;
#~ AddRule 'all', ['%TARGET_PATH/all' => '[path]/a.c', 'lib.o'], "echo hi", sub{} ;
#~ AddRule 't1', ['*.c' => '*.o'] ;
#~ #AddRule 't2', ['*.c' => '*.c'] ;
#~ AddRule 't3', ['*.c' => 'subdir/*.o'] ;
#~ AddRule 't4', ['*.c' => '/full/whatever.o'] ;
#~ AddRule 't5', ['*/*.c' => '/full/whatever.o'] ;
#~ AddRule 't6', ['*.c' => './*.o'] ;
#~ AddRule 't7', ['*.o' => 'sub/*.c'] ;

AddSubpbsRule('dir1', 'dir1/1.o', 'dir1/Pbsfile.pl', 'dir1');
AddSubpbsRule('dir2', '*dir1/1.o', 'dir1/Pbsfile.pl', 'dir1');

#~ AddTrigger 'T2', ['Y' => 'z2', 'z0', 'all'] ;
#~ AddRule 't8', ['Y' => 'all'] ;
