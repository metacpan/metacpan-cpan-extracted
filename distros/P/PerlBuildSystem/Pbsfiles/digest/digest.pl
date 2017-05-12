
=head1 PBSFILE USER HELP

=head2 Top rules

=over 2 

=item * all

=back

=cut

AddFileDependencies('MANIFEST') ;
AddNodeFileDependencies(qr/^.\/z0$/, 'pbs.html') ;
AddNodeFileDependencies(qr/c/, 'pbs.pod') ;
AddNodeVariableDependencies(qr/c/, 'a' => 1, 'b' => '2') ;

AddRule '', ['c'] => "touch %FILE_TO_BUILD" ; ;


