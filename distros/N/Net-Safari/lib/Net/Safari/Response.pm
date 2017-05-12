package Net::Safari::Response;

=head1 NAME

Net::Safari::Response - Results of a Safari search

=head1 SYNOPSIS

  use Net::Safari::Response;

  $resp = $net_safari->search();
  $resp = Net::Safari::Response->new( xml => $xml);

  my @books = $resp->books;

=head1 DESCRIPTION

See Net::Safari for general usage info.

Normally this object will be created for you after a call to
Net::Safari->search().

=head1 USAGE


=cut

#TODO - Add error message method, see Safari.pm SYNOPSIS.
use strict;
use XML::Simple;
use LWP::UserAgent;
use URI::Escape;
use Class::Accessor;
use Class::Fields;
use Data::Dumper;
use Net::Safari::Response::Book;

use base qw(Class::Accessor Class::Fields);
use fields qw(raw_response is_success);
Net::Safari::Response->mk_accessors( Net::Safari::Response->show_fields('Public') );

=head2 new()

my $resp = Net::Safari::Response->new( xml => $xml );

The Response object is created from the raw xml returned by calls to Safari.

=cut

sub new
{
	my ($class, %args) = @_;

	my $self = bless ({}, ref ($class) || $class);

    $self->raw_response( $args{xml} );

    $self->_init();

	return ($self);
}

sub _init {
    my $self = shift;
    #TODO: Handle error responses;
    my $ref = XMLin($self->raw_response, 
        'noattr' => 1, 
        'forcearray' => [ qw(book author content hlhit subject) ]
    );

    if ( !(ref $ref eq "HASH") ) 
    {
        #TODO: Error handling
        $self->is_success(0);
    }
    elsif ($ref->{book}) 
    {
        $self->is_success(1);
        $self->_set_books($ref->{book});
    }
}

sub _set_books {
    my $self = shift;
    my $books_ref = shift;
    
    my @books;
    foreach my $book (@$books_ref) {
        push @books, Net::Safari::Response::Book->new(%$book);
    }
    $self->{_books} = \@books;
}

=head2 books()


=cut

sub books {
    my $self = shift;
    if ($self->{_books}) { return @{$self->{_books}}; }
    else { return (); }
}

sub sections {

}

sub as_xml {
    my $self = shift;

    return $self->raw_response();
}

 
=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Tony Stubblebine
	cpan@tonystubblebine.com
	http://www.tonystubblebine.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut


1; #this line is important and will help the module return a true value
__END__

