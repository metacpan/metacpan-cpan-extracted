package RDF::Redland::DIG;

use strict;
use warnings;

use RDF::Redland::DIG::KB;

use constant GETID_REQ => q|<?xml version="1.0"?>
<getIdentifier xmlns="http://dl.kr.org/dig/2003/02/lang"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" />
|;

=pod

=head1 NAME

RDF::Redland::DIG - DIG extension for Redland RDF (Reasoner)

=head1 SYNOPSIS

  my $model = new RDF::Redland::Model ....

  use RDF::Redland::DIG;
  my $r = new RDF::Redland::DIG (url => http://localhost:8081/);

  use RDF::Redland::DIG::KB;
  my $kb = $r->kb;   # create an empty knowledge base there
  eval {
     $kb->tell ($model);
  }; die $@ if $@;

  my %children = $kb->children ('urn:pizza', 'urn:topping');
  # see RDF::Redland::DIG::KB

=head1 DESCRIPTION

Instances of this class represent a handle to a remote instance of a DIG reasoner.

DIG is a protocol which applications can use to use reasoning services provided by such a reasoner.

   http://dl-web.man.ac.uk/dig/

=head1 INTERFACE

=head2 Constructor

The constructor connects an in-memory object with a remote instance of a DIG reasoner. The only
mandatory parameter is the URL to address the reasoner.

Optionally the following fields are processed:

=over

=item C<ua> (default: L<LWP::UserAgent>)

Here you can pass in your custom made HTTP client. Must subclass L<LWP::UserAgent>.

=back

=cut

sub new {
    my $class = shift;
    my $url   = shift;
    my %options = @_;
    $options{url} = $url or die "no URL provided to contact DIG reasoner";
    
    unless ($options{ua}) {
    	use LWP::UserAgent;
    	$options{ua} = LWP::UserAgent->new;
	    $options{ua}->agent ('Redland DIG Client');
	}
	
    my $req = HTTP::Request->new(POST => $options{url});
    $req->content_type('text/xml');
    $req->content(GETID_REQ);

    # Pass request to the user agent and get a response back
    my $res = $options{ua}->request ($req);
	
    # Check the outcome of the response
    die "reasoner could not be contacted at $options{url}" unless $res->is_success;

    return bless \ %options, $class;
}

=pod

=head2 Methods

=over

=item B<kb>

This method clones one knowledge base from the reasoner. You can have any number of these.

=cut

sub kb {
    my $self = shift;
    return new RDF::Redland::DIG::KB ($self);
}

=pod

=back

=head1 COPYRIGHT AND LICENCE

Copyright 2008 by Lara Spendier and Robert Barta

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

Work supported by the Austrian Research Centers Seibersdorf (Smart Systems).

=cut

our $VERSION = 0.04;

1;

