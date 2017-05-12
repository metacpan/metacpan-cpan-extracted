package MooseX::Storage::Format::XML::Simple;
use Moose::Role;

use warnings;
use strict;

use XML::Simple;

requires 'pack';
requires 'unpack';

=head1 NAME

MooseX::Storage::Format::XML::Simple - An XML::Simple serialization role

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

=head1 SYNOPSIS

	package Point;
	use Moose;
	use MooseX::Storage;

	with Storage('format' => 'XML::Simple');

	has 'x' => (is => 'rw', isa => 'Int');
	has 'y' => (is => 'rw', isa => 'Int');

	1;

	my $p = Point->new(x => 10, y => 10);

	## methods to freeze/thaw into 
	## a specified serialization format
	## (in this case XML)

	# pack the class into a XML string
	$p->freeze(); 

	# <opt>
	#   <__CLASS__>Point</__CLASS__> 
	#   <x>10</x>
	#   <y>10</y>
	# </opt>  

	# unpack the XML string into a class
	my $p2 = Point->thaw(<<XML);  
    <opt>
      <__CLASS__>Point</__CLASS__>
      <x>10</x>
      <y>10</y>
    </opt>
	XML

=head1 METHODS

=over 4 

=item B<freeze>

Serializes the object into the XML string. Uses L<NoAttr|XML::Simple/NoAttr> 
set to 1 while producing XML output.

=cut

sub freeze {
    my ( $self, @args ) = @_;
    XMLout( $self->pack(@args), NoAttr => 1 );
}

=item B<thaw($xml)>

Deserializes the object from the XML string. Uses 
L<SuppressEmpty|XML::Simple/SuppressEmpty> set to C<undef> while producing XML 
output.

=cut

sub thaw {
    my ( $class, $xml, @args ) = @_;
    $class->unpack( XMLin( $xml, SuppressEmpty => undef ), @args );
}

=back

=head1 CAVEATS

Some attribute names/hashkeys (eg. starting with digit) will invalidate 
generated XML output.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Bruno Czekay E<lt>brunorc@cpan.orgE<gt>

Based on the code by Yuval Kogman.

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
