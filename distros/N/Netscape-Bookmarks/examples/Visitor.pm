package Visitor;

=encoding utf8

=head1 NAME

Visitor - a sample Visitor object for Netscape bookmarks

=head1 SYNOPSIS

	use Netscape::Bookmarks;
	use Visitor;

	my $netscape = Netscape::Bookmarks->new( 'Bookmarks.html' );
	my $visitor = Visitor->new();

	my $netscape->introduce( $visitor );

=head1 DESCRIPTION

This class is an example Visitor class for Netscape::Bookmarks.
It dispatches the visit to a method depending on what sort
of object it visits.  For all objects, a short message is
output to standard output.  For a link object, it calls in
HTTP::SimpleLinkChecker if you have it and then checks the
link.

You can use this as a starting point for your own Visitor.

=head2 METHODS

=over 4

=item new()

No big whoop.  It simply creates an uninteresting object that
knows it's class so we can dispatch with it.

=cut

sub new
	{
	my( $class ) = shift;

	my $name = __PACKAGE__;

	bless \$name, $class;
	}

=item visit()

The Netscape::AcceptVisitors module requires this method.  Use
visit() to dispatch a visit to the right method.  How you do that
is up to you.

Beyond that, look at the code.

=cut

sub visit
	{
	my( $self, $object ) = @_;

	my $class = ref $object;
	$class =~ s/.*:://;

	$self->$class($object);
	}

sub Category
	{
	my( $self, $object ) = @_;

	print STDERR "\tFound category!\n";
	}

sub Alias
	{
	my( $self, $object ) = @_;

	print STDERR "\tFound Alias!\n";
	}

sub Separator
	{
	my( $self, $object ) = @_;

	print STDERR "\tFound Separator!\n";
	}

sub Link
	{
	my( $self, $object ) = @_;
	print STDERR "\tFound Link!\n";
	return unless require HTTP::SimpleLinkChecker;

	my $code = HTTP::SimpleLinkChecker::check_link( $object->href );

	print STDERR "\t\tLink has status $code\n";
	}

1;
__END__
=back

=head1 AUTHOR

brian d foy C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2015, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<Netscape::Bookmarks>, L<Netscape::Bookmarks::AcceptVisitor>

=cut
