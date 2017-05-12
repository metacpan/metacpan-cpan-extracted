package Net::Safari::Response::Author;

=head1 NAME

Net::Safari::Response::Author- Author node returned by Safari

=head1 SYNOPSIS

  use Net::Safari::Response::Author;
  my $book = Net::Safari::Response::Author->new(%author_ref);

  my @authors = $response->book->authors;

  print $author->firstname;

=head1 DESCRIPTION 

See Net::Safari for general usage info.

In most cases this object is created for you by Net::Safari::Response after a Net::Safari->search() call.

=head1 ACCESSORS
The accessor descriptions are mostly pulled from the official spec:
http://safari.oreilly.com/affiliates/?p=response

=head2 firstname()

Author firstname.

=head2 lastname()

Author lastname.

=head2 fullname()

Firstname + Lastname. Just for kicks, otherwise this would be a really boring
module.

=cut


use strict;

our $VERSION = 0.01;

use LWP::UserAgent;
use URI::Escape;
use Class::Accessor;
use Class::Fields;
use Data::Dumper;

use base qw(Class::Accessor Class::Fields);

our @BASIC_FIELDS = qw(
              firstname
              lastname
              ); 

use fields @BASIC_FIELDS;
Net::Safari::Response::Author->mk_accessors(@BASIC_FIELDS);

=head1 METHODS

=head2 new()

$book = Net::Safari::Response::Section->new($ref);

Takes a hash represenation of the XML returned by Safari. Normally this is
taken care of by Net::Safari::Response::Book.

=cut

sub new
{
	my ($class, %args) = @_;

	my $self = bless ({}, ref ($class) || $class);

    $self->_init(%args);

	return ($self);
}

sub _init {
    my $self = shift;
    my %args = @_;
   
    #Firstname
    $self->firstname($args{firstname});

    #Lastname
    $self->lastname($args{lastname}); 
}

sub fullname {
    my $self = shift;
    
    return $self->firstname . " " . $self->lastname;
}

=head1 BUGS

None yet.

=head1 SUPPORT

If you find a bug in the code or find that the code doesn't match Safari API, please send me a line.

If the Safari API is down or has bugs, please contact Safari directly:
affiliates@safaribooksonline.com

=head1 ACKNOWLEDGMENTS

Adapted from the design of Net::Amazon by Mike Schilli. 

Some documentation based on the source Safari documentation:
http://safari.oreilly.com/affiliates/?p=web_services

=head1 AUTHOR

    Tony Stubblebine	
    tonys@oreilly.com

=head1 COPYRIGHT

Copyright 2004 by Tony Stubblebine (tonys@oreilly.com)

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut



1; #this line is important and will help the module return a true value
__END__

