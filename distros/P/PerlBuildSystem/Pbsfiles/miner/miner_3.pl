=head1 PBSFILE USER HELP

Test configuration correctness

=head2 Top rules

=over 2 

=item * '*.o'

=back

=cut

AddConfig 'MULTIPLE_CC' => 'miner_3_multiple_cc' ;

#~ AddRule 'o2c', ['*/*.o' => '*.c'] ;

#~ PbsUse('MetaRules/FirstAndOnlyOneOnDisk') ;

#~ AddRuleTo 'BuiltIn', 's_objects', [ '*.o' => '*.s' ], "AS ASFLAGS -o FILE_TO_BUILD DEPENDENCY_LIST";
#~ AddRuleTo 'BuiltIn', 'c_objects', [ '*.o' => '*.c' ], "CC CFLAGS -o FILE_TO_BUILD -c DEPENDENCY_LIST" ; 

PbsUse('Rules/C') ;

#~ AddRuleTo 'BuiltIn', [META_RULE], 'o_cs_meta', [\&FirstAndOnlyOneOnDisk, ['c_objects', 's_objects'],  'c_objects'] ;
#~ ReplaceRuleTo 'BuiltIn', [META_RULE], 'o_cs_meta', [\&FirstAndOnlyOneOnDisk, ['c_objects', 's_objects'],  's_objects'] ;
