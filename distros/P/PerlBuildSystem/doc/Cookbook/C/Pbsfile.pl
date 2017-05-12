=for PBS =head1 Top rules

=over 2 

=item * 'all'

=back

=cut

PbsUse('Configs/gcc') ;
PbsUse('Rules/C') ;

AddRule [VIRTUAL], 'all', ['all' => 'a.out'], BuildOk('') ;

AddRule 'a.out', ['a.out' => 'hello_world.o']
	, ["%CC -o %FILE_TO_BUILD %DEPENDENCY_LIST"] ;

