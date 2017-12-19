package Net::Ethereum;

use 5.026000;
use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.01';



sub new
{
  my ($this, $api_url) = @_;
  my $self = {};
  bless( $self, $this );

  $self->{api_url} = $api_url;
  return $self;
}



sub eth_accounts($)
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0",method => "eth_accounts", params => [], id => 1 };
  return $this->_node_request($rq);
}


sub _node_request($)
{
  my ($this, $json_data) = @_;
  my $req = HTTP::Request->new(POST => $this->{api_url});
  $req->header('Content-Type' => 'application/json');
  my $ua = LWP::UserAgent->new;
  my $data = encode_json($json_data);
  $req->add_content_utf8($data);
  return decode_json($ua->request($req)->{ _content });
}




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::Ethereum - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Net::Ethereum;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Net::Ethereum, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Alexandre Frolov, E<lt>frolov@itmatrix.ruE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Alexandre Frolov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
