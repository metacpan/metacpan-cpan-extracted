
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * no rule defined

=back

=cut

AddConfig 'a' => 1 ;
AddConfig 'a' => 2 ;

AddConfig 'a:LOCAL' => 1 ;
AddConfig 'a:LOCAL' => 10 ;

AddConfig 'b:locked' => 1 ;
AddConfig 'b:force' => 2 ;
AddConfig 'b' => 2 ;


