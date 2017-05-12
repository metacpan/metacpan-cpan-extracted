package Net::CapsuleCRM;
$Net::CapsuleCRM::VERSION = '1.151910';
use strict;
use warnings;
use Moo;
use Sub::Quote;
use Method::Signatures;
use Cpanel::JSON::XS;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;

# ABSTRACT: Connect to the Capsule API (www.capsulecrm.com)


has 'debug' => (is => 'rw', predicate => 'is_debug');
has 'error' => (is => 'rw', predicate => 'has_error');
has 'token' => (is => 'rw', required => 1);
has 'ua' => (is => 'rw', 
  default => sub { LWP::UserAgent->new( agent => 'Perl Net-CapsuleCRM'); } );
has 'target_domain' => (is => 'rw', default => sub { 'test.capsulecrm.com' } );
has 'xmls' => ( is => 'rw', default => sub { return XML::Simple->new(
  NoAttr => 1, KeyAttr => [], XMLDecl => 1, SuppressEmpty => 1, ); }
);

method endpoint_uri { return 'https://' . $self->target_domain . '/api/'; }

method _talk($command,$method,$content?) {
  my $uri = URI->new($self->endpoint_uri);
  $uri->path("api/$command");

  $self->ua->credentials( 
    $uri->host . ':'.$uri->port,
    'seamApp',
    $self->token => 'x'
  );
  
  print "$uri\n" if $self->debug;

  my $res;
  my $type = ref $content  eq 'HASH' ? 'json' : 'xml';
  if($method =~ /get/i){
    if(ref $content eq 'HASH') {
      $uri->query_form($content);
    }
    $res = $self->ua->request(
      GET $uri, #content is ID in this instance.
      Accept => 'application/json', 
      Content_Type => 'application/json',
    );
  } else {
    #$content = $self->_template($content) if $content;
    if($type eq 'json') {
      print "Encoding as JSON\n" if $self->debug;
      $content = encode_json $content;
      print "$content\n" if $self->debug;
      $res = $self->ua->request(
        POST $uri,
        Accept => 'application/json', 
        Content_Type => 'application/json',
        Content => $content,
      );
    } else {
      #otherwise XML
      $content = $self->xmls->XMLout($content, RootName => $command);
      print "Encoding as XML\n" if $self->debug;
      $res = $self->ua->request(
        POST $uri,
        Accept => 'text/xml', 
        Content_Type => 'text/xml',
        Content => $content,
      );
    }


  }
  
  if ($res->is_success) {
    print "Server said: ", $res->status_line, "\n" if $self->debug;
    if($res->status_line =~ /^201/) {
      return (split '/', $res->header('Location'))[-1]
    } else {
      print $res->content. "\n" if $self->debug;
      if($type eq 'json') {
        return decode_json $res->content;
      } elsif($res->content) {
        return XMLin $res->content;
      } else {
        return 1;
      }
    }
  } else {
    $self->error($res->status_line);
    warn $self->error;
    if ($self->debug) {
      print $res->content;
    }
  }
  
}



method find_party_by_email($email) {
  my $res = $self->_talk('party', 'GET', {
    email => $email,
    start => 0,
  });
  return $res->{'parties'}->{'person'}->{'id'} || undef;
}


method find_party($id) {
  my $res = $self->_talk('party/'.$id, 'GET', $id);
  return $res->{'parties'}->{'person'}->{'id'} || undef;
}


method create_person($data) {
  return $self->_talk('person', 'POST', { person => $data } );
}


method create_organisation($data) {
  return $self->_talk('organisation', 'POST', { organisation => $data } );
}

method add_tag($id, @tags) {
  # my $data = $self->xmls->XMLout(
  #   { tag => [ map { name => $_ }, @tags ] }, RootName => 'tags'
  # );
  foreach(@tags) {
    $self->_talk("party/$id/tag/$_", 'POST');
  }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::CapsuleCRM - Connect to the Capsule API (www.capsulecrm.com)

=head1 VERSION

version 1.151910

=head1 SYNOPSIS

my $foo = Net::CapsuleCRM->new(
  token => 'xxxx',
  target_domain => 'test.capsulecrm.com',
  debug => 0,
);

=head2 find_party_by_email

find by email

=head2 find_party

find by id

=head2 create_person

$cap->create_person({
  contacts => {
    email => {
      emailAddress => 'xxx',
    },
    address => {
      type => 'xxx',
      street => "xxx",
      city => 'xxx',
      zip => 'xxx',
      country => 'xxx',
    },
    phone => {
      type => 'Home',
      phoneNumber => '123456',
    },
  },
  title => 'Mr',
  firstName => 'Simon',
  lastName => 'Elliott',
});

=head2 create_organization

See Person

=head2 add_tag

$cap->add_tag($person_id,'customer','difficult');

=head1 AUTHOR

Simon Elliott <cpan@papercreatures.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Simon Elliott.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
