package Empty;

sub foo {}
sub bar {}

1;
__END__

# test module - two subs, one with docs, one with empty pod section

=head2 foo

=head2 bar

bar does things!

=cut

