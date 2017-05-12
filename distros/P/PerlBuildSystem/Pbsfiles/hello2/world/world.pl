=head1 PBSFILE USER HELP

To be used as a subpbs only!

=head2 Top rules

=over 2 

=item * none

=back

=cut

PbsUse('Configs/Compilers/gcc') ;
PbsUse('Rules/C') ;

AddVariableDependencies(CFLAGS => GetConfig('CFLAGS')) ;

