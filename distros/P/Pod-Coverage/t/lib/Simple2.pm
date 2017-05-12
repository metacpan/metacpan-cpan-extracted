package Simple2;

# test module - four subs, one with embedded pod item, one with a head2, one
# with a method call, one with nowt

sub foo {}
sub baz {}
sub qux {}
sub naked {}



1;
__END__

=head2 Methods

=over

=item foo

this is foo

=item $object->baz()

=item B<qux>

=back

=cut

