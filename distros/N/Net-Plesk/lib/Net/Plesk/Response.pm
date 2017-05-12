package Net::Plesk::Response;

use strict;
use XML::Simple;
use XML::XPath;
use XML::XPath::XMLParser;

=head1 NAME

Net::Plesk::Response - Plesk response object

=head1 SYNOPSIS

  my $response = $plesk->some_method( $and, $args );

  if ( $response->is_success ) {

    my $id  = $response->id;
    #...

  } else {

    my $error = $response->error; #error code
    my $errortext = $response->errortext; #error message
    #...
  }

=head1 DESCRIPTION

The "Net::Plesk::Response" class represents Plesk responses.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  bless($self, $class);

  my $data = shift;
  if ($data =~ /^\<\?xml version=\"1.0\"\?\>(.*)$/s){
    $data=$1;
  }else{
    $data =~ s/[^\w\s]/ /g;  # yes, we lose stuff
    $data = '<?xml version="1.0"?>' .
      '<packet version="' . $self->{'version'} . '">' .
      "<system><status>error</status><errcode>500</errcode>" .
      "<errtext>Malformed Plesk response:" . $data .  "</errtext>".
      "</system></packet>";
  } 

  my $xp = XML::XPath->new(xml => $data);
  my $nodeset = $xp->find('//result');
  foreach my $node ($nodeset->get_nodelist) {
    push @{$self->{'results'}}, XML::XPath::XMLParser::as_string($node);
  }
  $nodeset = $xp->find('//system');
  foreach my $node ($nodeset->get_nodelist) {
    my $parsed = XML::XPath::XMLParser::as_string($node);
    $parsed =~ s/\<(\/?)system\>/<$1result>/ig;
    push @{$self->{'results'}}, $parsed;
  }

  $self;
}

sub is_success { 
  my $self = shift;
  my $status = 1;
  foreach my $result (@{$self->{'results'}}) {
    $status = (XMLin($result)->{'status'} eq 'ok');
    last unless $status;
  }
  $status;
}

sub error {
  my $self = shift;
  my @errcode;
  foreach my $result (@{$self->{'results'}}) {
    my $errcode = XMLin($result)->{'errcode'};
    push @errcode, $errcode if $errcode;
  }
  return wantarray ? @errcode : $errcode[0];
}

sub errortext {
  my $self = shift;
  my @errtext;
  foreach my $result (@{$self->{'results'}}) {
    my $errtext = XMLin($result)->{'errtext'};
    push @errtext, $errtext if $errtext;
  }
  return wantarray ? @errtext : $errtext[0];
}

sub id {
  my $self = shift;
  my @id;
  foreach my $result (@{$self->{'results'}}) {
    my $id = XMLin($result)->{'id'};
    push @id, $id if $id;
  }
  return wantarray ? @id : $id[0];
}


=head1 BUGS

Needs better documentation.

=head1 SEE ALSO

L<Net::Plesk>,

=head1 AUTHOR

Jeff Finucane E<lt>jeff@cmh.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Jeff Finucane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
