# ABSTRACT: http://www.bearead.org
package Novel::Robot::Parser::bearead;
use strict;
use warnings;
use utf8;
use JSON;

use base 'Novel::Robot::Parser';

sub base_url { 'https://www.bearead.com' }

sub generate_novel_url {
  my ( $self, $index_url ) = @_;
  my ( $bid ) = $index_url =~ m#bid=([^&]+)#;
  return ( 'https://www.bearead.com/api/book/detail', "bid=$bid" );
}

sub parse_novel {
  my ( $self, $h, $rr ) = @_;
  my $r = decode_json( $$h );
  $r = $r->{data};
  my %res;
  $res{book}         = $r->{name};
  $res{writer}       = $r->{author}{nickname};
  $res{floor_list} = [
    map { { url       => 'https://www.bearead.com/api/book/chapter/content',
        post_data => "bid=$_->{bid}&cid=$_->{cid}",
        title     => $_->{name},
      } } @{ $r->{chapter} } ];
  return \%res;
}

sub parse_novel_item {
  my ( $self, $h ) = @_;
  my $r = decode_json( $$h );
  return { content => $r->{data}{content} };
}

1;
