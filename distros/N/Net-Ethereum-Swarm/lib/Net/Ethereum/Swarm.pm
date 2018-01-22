package Net::Ethereum::Swarm;

use 5.020002;
use strict;
use warnings;

use LWP::UserAgent;
use File::Slurp;
use HTTP::Request ();
use JSON;


our $VERSION = '0.04';



=pod

=encoding utf8

=head1 NAME

  Net::Ethereum::Swarm - Perl Framework for a distributed storage platform and content distribution service Ethereum Swarm.

=head1 SYNOPSIS


# Upload text file to Ethereum Swarm

  use Net::Ethereum::Swarm;
  my $uploaded_file_path = $ARGV[0];
  my $sw_node = Net::Ethereum::Swarm->new('http://localhost:8500/');
  my $rc = $sw_node->_swarp_node_upload_text_file($uploaded_file_path, 'plain/text; charset=UTF-8');
  print Dumper($rc), "\n";


# Upload binary file to Ethereum Swarm

  use Net::Ethereum::Swarm;
  my $uploaded_file_path = $ARGV[0];
  my $sw_node = Net::Ethereum::Swarm->new('http://localhost:8500/');
  my $rc = $sw_node->_swarp_node_upload_binary_file($uploaded_file_path, 'image/jpeg');
  print Dumper($rc), "\n";


# Get manifest by manifest id

  use Net::Ethereum::Swarm;
  my $manifest_id = $ARGV[0];
  my $sw_node = Net::Ethereum::Swarm->new('http://localhost:8500/');
  my $rc = $sw_node->_swarp_node_get_manifest($manifest_id);
  print Dumper($rc), "\n";


# Get file from Ethereum Swarm

  use Net::Ethereum::Swarm;
  my $manifest_id = $ARGV[0];
  my $file_path_to_save = $ARGV[1];
  my $sw_node = Net::Ethereum::Swarm->new('http://localhost:8500/');
  my $rc = $sw_node->_swarp_node_get_file($manifest_id, $file_path_to_save, 'plain/text; charset=UTF-8');
  print Dumper($rc), "\n";



=head1 DESCRIPTION

  Net::Ethereum::Swarm - Perl Framework for a distributed storage platform and content distribution service Ethereum Swarm.

=head1 FUNCTIONS



=head2 new()

  my $sw_node = Net::Ethereum::Swarm->new('http://localhost:8500/');

=cut

sub new
{
  my ($this, $swarm_api_url) = @_;
  my $self = {};
  bless( $self, $this );

  $self->{api_url} = $swarm_api_url;
  $self->{debug} = 0;

  return $self;
}

=pod

=head2 _swarp_node_get_manifest

  Get manifest by manifest id
  my $rc = $sw_node->_swarp_node_get_manifest($manifest_id);

=cut

sub _swarp_node_get_manifest()
{
  my ($this, $manifest_id) = @_;
  my $header = ['Content-Type' => 'plain/text'];
  my $rc = $this->_swarp_node_request('GET', 'bzz-list:/'.$manifest_id.'/', $header, '');
  my $manifest = JSON::decode_json($rc);
  return $manifest;
}


=pod

=head2 _swarp_node_get_file

  Get file from Ethereum Swarm
  my $rc = $sw_node->_swarp_node_get_file($manifest_id, $file_path_to_save, 'plain/text; charset=UTF-8');

=cut

sub _swarp_node_get_file()
{
  my ($this, $manifest_id, $content_type, $path) = @_;
  my $header = ['Content-Type' => $content_type];
  my $file_content = $this->_swarp_node_request('GET', 'bzz:/'.$manifest_id.'/'.$path, $header, '');
  return $file_content;
}


=pod

=head2 _swarp_node_upload_text_file

  Upload text file to Ethereum Swarm

  my $rc = $sw_node->_swarp_node_upload_text_file($uploaded_file_path, 'plain/text; charset=UTF-8');

=cut


sub _swarp_node_upload_text_file()
{
  my ($this, $uploaded_file_path, $content_type) = @_;

  my $file_content = read_file( $uploaded_file_path, scalar_ref => 1);
#  my $header = ['Content-Type' => 'plain/text; charset=UTF-8'];
  my $header = ['Content-Type' => $content_type];
  my $ua_rc = $this->_swarp_node_request('POST', 'bzz:/', $header, $file_content);
  return $ua_rc;
}


=pod

=head2 _swarp_node_upload_binary_file

  Upload binary file to Ethereum Swarm

  my $rc = $sw_node->_swarp_node_upload_binary_file($uploaded_file_path, 'image/jpeg');

=cut


sub _swarp_node_upload_binary_file()
{
  my ($this, $uploaded_file_path, $content_type) = @_;

  my $file_content = read_file( $uploaded_file_path , binmode => ':raw' , scalar_ref => 1 );
#  my $header = ['Content-Type' => 'image/jpeg'];
  my $header = ['Content-Type' => $content_type];
  my $ua_rc = $this->_swarp_node_request('POST', 'bzz:/', $header, $file_content);
  return $ua_rc;
}


=pod

=head2 _swarp_node_request

  Internal method.
  Send request to Ethereum Swarm

  my $ua_rc = $this->_swarp_node_request('POST', 'bzz:/', $header, $file_content);

=cut


sub _swarp_node_request()
{
  my ($this, $rq_type, $bzz_protocol, $header, $content) = @_;
  my $req = HTTP::Request->new($rq_type, $this->{api_url}.$bzz_protocol, $header, $content);
  my $ua = LWP::UserAgent->new;
  return $ua->request($req)->{ _content };
}



=pod

=head2 set_debug_mode

  Set dubug mode. Debug info printed to console.
  $node->set_debug_mode($mode);

  $mode: 1 - debug on, 0 - debug off.

=cut

sub set_debug_mode()
{
  my ($this, $debug_mode) = @_;
  $this->{debug} = $debug_mode;
}



1;
__END__

=head1 SEE ALSO

=over 12

=item 1

Swarm documentation:
L<https://swarm-guide.readthedocs.io/en/latest/index.html>

=item 2

GitHub Swarm guide:
L<https://github.com/ethersphere/swarm-guide/blob/master/contents/usage.rst>

=item 3

Swarm API improvements :
L<https://gist.github.com/lmars/a37f3eaa129f95273c8c536e98920368>

=back

=head1 AUTHOR

    Alexandre Frolov, frolov@itmatrix.ru

    L<https://www.facebook.com/frolov.shop2you>
    The founder and director of SAAS online store service Shop2YOU, L<http://www.shop2you.ru>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2018 by Alexandre Frolov

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself, either Perl version 5.26.0 or,
    at your option, any later version of Perl 5 you may have available.


=cut

