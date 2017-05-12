package Net::isoHunt;
BEGIN {
  $Net::isoHunt::VERSION = '0.102770';
}

# ABSTRACT: Access isohunt.com from Perl

use Moose;

use Net::isoHunt::Request;
use Net::isoHunt::Response;
use Net::isoHunt::Response::Image;
use Net::isoHunt::Response::Item;

sub prepare_request {
    my $self = shift;
    return Net::isoHunt::Request->new(@_);
}

__PACKAGE__->meta()->make_immutable();

no Moose;

1;



=pod

=head1 NAME

Net::isoHunt - Access isohunt.com from Perl

=head1 VERSION

version 0.102770

=head1 SYNOPSIS

    use Net::isoHunt;

    my $ih = Net::isoHunt->new();

    my $ih_request = $ih->prepare_request( { 'ihq' => 'ubuntu' } );
    $ih_request->start(21);
    $ih_request->rows(20);
    $ih_request->sort('seeds');

    my $ih_response = $ih_request->execute();

    print 'Title: ',       $ih_response->title(),       "\n";
    print 'Description: ', $ih_response->description(), "\n";

    my $image = $ih_response->image();
    print 'Image title: ', $image->title(), "\n";
    print 'Image URL: ',   $image->url(),   "\n";

    my @items = @{ $ih_response->items() };
    my $item  = shift @items;

=head1 ATTRIBUTES

=head2 C<new>

Constructs and returns a L<Net::isoHunt> object.

=head1 METHODS

=head2 C<prepare_request>

Returns a L<Net::isoHunt::Request> object based on the arguments passed. Accepts
a hash reference. Valid arguments are listed in L<Net::isoHunt::Request>. C<ihq>
is required.

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

