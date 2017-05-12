=head1 PBSFILE USER HELP

Test configuration correctness

=head2 Top rules

=over 2 

=item * 'usb.o'

=back

=cut

#~ ExcludeFromDigestGeneration( 'c_files' => qr/\.c$/) ;
AddRule 'usb', ['*/usb.o' => 'usb.c'], BuildOk("Builder1") ;
AddRule 'usb.c', ['*/usb.c'], BuildOk("Builder usb") ;

