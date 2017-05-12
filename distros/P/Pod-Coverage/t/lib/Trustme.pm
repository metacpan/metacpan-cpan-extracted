package Trustme;

# test module - four subs, one with embedded pod item, one with a head2, one
# with a method call, one with nowt

sub foo {}
sub bar {}
sub baz {}
sub naked {}
sub private {}
sub trustme {}
sub trust_me {}


1;
__END__


=head2 METHODS

=over 4

=item foo

foo does foo to things

=item bar

bar does bar to things

=item baz

baz does baz to things

=back

This paragraph should be considered to be the docs for any
method containing the letter u in its name.

=cut
