package PLN::PT;
# ABSTRACT: interface for the http://pln.pt web service
$PLN::PT::VERSION = '0.005';
use strict;
use warnings;

use JSON::MaybeXS ();
use CHI;
use Digest::MD5 qw/md5_base64/;
use LWP::UserAgent;
use Encode;

sub new {
  my ($class, $url) = @_;
  my $self = bless( {url=>$url}, $class);

  $self->{ua} = LWP::UserAgent->new;
  $self->{cache} = CHI->new( driver => 'Memory', global => 1 );

  return $self;
}

sub tokenizer {
  my ($self, $text, $opts) = @_;

  my $url = $self->_cat('tokenizer');
  $url .= '?' . $self->_args($opts);

  return $self->_post($url, $text, $opts);
}

sub tagger {
  my ($self, $text, $opts) = @_;

  my $url = $self->_cat('tagger');
  $url .= '?' . $self->_args($opts);

  return $self->_post($url, $text, $opts);
}

sub dep_parser {
  my ($self, $text, $opts) = @_;

  my $url = $self->_cat('dep_parser');
  $url .= '?' . $self->_args($opts);

  return $self->_post($url, $text, $opts);
}

sub tf {
  my ($self, $text, $opts) = @_;

  my $url = $self->_cat('tf');
  $url .= '?' . $self->_args($opts);

  return $self->_post($url, $text, $opts);
}

sub stopwords {
  my ($self, $opts) = @_;

  my $url = $self->_cat('stopwords');
  $url .= '?' . $self->_args($opts);

  return $self->_get($url, $opts);
}

sub _post {
  my ($self, $url, $text, $opts) = @_;

  my $key = $url . '-' . md5_base64(Encode::encode_utf8($text));
  my $data = $self->{cache}->get($key);

  unless ($data) {
    my $req = HTTP::Request->new(POST => $url);
    $req->content(Encode::encode_utf8($text));

    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
      $data = $res->decoded_content;
      $data = $res->content unless $data;
      $self->{cache}->set($key, $data);
    }
    else {
      print STDERR "HTTP POST error: ", $res->code, " - ", $res->message, "\n";
      return undef;
    }
  }

  return $data if ($opts->{output} and $opts->{output} eq 'raw');
  return JSON::MaybeXS->new(utf8 => 1)->decode($data);
}

sub _get {
  my ($self, $url, $opts) = @_;

  my $key = $url . '-' . md5_base64(join('', values %$opts));
  my $data = $self->{cache}->get($key);

  unless ($data) {
    my $req = HTTP::Request->new(GET => $url);

    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
      $data = $res->decoded_content;
      $data = $res->content unless $data;
      $self->{cache}->set($key, $data);
    }
    else {
      print STDERR "HTTP GET error: ", $res->code, " - ", $res->message, "\n";
      return undef;
    }
  }

  return $data if ($opts->{output} and $opts->{output} eq 'raw');
  return JSON::MaybeXS->new(utf8 => 1)->decode($data);
}

sub _cat {
  my ($self, @args) = @_;

  my @parts = ($self->{url});
  push @parts, @args;

  return join('/', @parts);
}

sub _args {
  my ($self, $opts) = @_;

  my @args;
  foreach (keys %$opts) {
    push @args, join('=', $_, $opts->{$_});
  }

  return join('&', @args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PLN::PT - interface for the http://pln.pt web service

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    # using as a lib
    my $pln = PLN::PT->new('http://api.pln.pt');
    my $data = $pln->tagger($txt);  # [['A','o',''DA0FS0','0.675415'], ...

    # using the pln-pt tool from the command line
    $ echo "A Maria tem razão . " | pln-pt tagger
    A o DA0FS0 0.675415
    Maria maria NCFS000 1
    tem ter VMIP3S0 0.999287
    razão razão NCFS000 0.65
    . . Fp 1

=head1 DESCRIPTION

This module implements an interface for the Natural Language Processing
(NLP) web service provided by L<http://pln.pt>.

=head1 METHODS

=head2 new

Create new object, given as argument the base endpoint for the web service.

Once the object is created, a set of methods described below can be used to
access several operations in the API. All the methods return a data
structure with the corresponding result, typically a list of tokens with
some extra information depending on the operation used.

=head2 tokenizer

Tokenize the text given as argument, i.e. split the text in tokens (words
by default), for more information on the tokenization operation
visit L<http://pln.pt/api>.

    $ echo "A Maria tem razão ." | pln-pt tokenizer
    A
    Maria
    tem
    razão
    .

=head2 tagger

Part-of-speech tagging the tokens in the text, given as argument, for more
information on the tagging operation visit L<http://pln.pt/api>.

    $ echo "A Maria tem razão ." | pln-pt tagger
    A o DA0FS0 0.675415
    Maria maria NCFS000 1
    tem ter VMIP3S0 0.999287
    razão razão NCFS000 0.65
    . . Fp 1

=head2 dep_parser

Build a dependency tree for the text given as argument, for more information
on the dependency tree visit L<http://pln.pt/api>.

    $ echo "A Maria tem razão ." | pln-pt dep_parser
    1	A	_	DET	art|<artd>|F|S	(...)	2	det	_	_
    2	Maria	_	PROPN	prop|F|S	(...)	3	nsubj	_	_
    3	tem	_	VERB	v-fin|PR|3S|IND	(...)	0	ROOT	_	_
    4	razão	_	NOUN	n|F|S	(...)	3	dobj	_	_
    5	.	_	PUNCT	punc	(...)	3	punct	_

=head1 ACKNOWLEDGEMENTS

This work is a result of the project “SmartEGOV: Harnessing EGOV for Smart
Governance (Foundations, methods, Tools) / NORTE-01-0145-FEDER-000037”,
supported by Norte Portugal Regional Operational Programme (NORTE 2020),
under the PORTUGAL 2020 Partnership Agreement, through the European Regional
Development Fund (EFDR).

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2017 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
