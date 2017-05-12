

=for PBS =head1 Top rules

=over 2

=item * all, tests an include file dependency

=item * a, test node dependencies with 3 cycles

=back

=cut

=head1 SYNOPSIS

2 c files including 2 header files but in a different order the header files include each other

This leads to a dependency when the tree is merged though it is not  an error when compiling each file per se

=cut

PbsUse('Configs/Compilers/gcc') ;
PbsUse('Builders/Objects') ; 
PbsUse('Rules/C') ; 

#-------------------------------------------------------------------------------

my @object_files = qw(a.c b.c) ;

AddRule [VIRTUAL], 'all',   [ 'all'     => 'cyclic_test' ], BuildOk("All finished.");
AddRule            'cyclic_test', [ 'cyclic_test' => 'cyclic_test.objects' ], BuildOk() ;

AddRule 'objects', ['cyclic_test.objects' => @object_files], \&CreateObjectsFile ;


#-------------------------------------------------------------------------------

AddRule 'a', ['a' => 'b', 'b2', 'b3'] ;
AddRule 'b', ['b' => 'c'] ;
AddRule 'c', ['c' => 'a'] ;

AddRule 'b2', ['b2' => 'c'] ;

AddRule 'b3', ['b3' => 'c3'] ;
AddRule 'c3', ['c3' => 'a'] ;


