# ABSTRACT: raw
=pod

=encoding utf8

=head1 FUNCTION

=head2 parse_novel

解析raw 文件
  
  my $raw_content_ref = $self->parse_novel( '/someotherdir/somefile.raw' );

=cut
package Novel::Robot::Parser::raw;
use strict;
use warnings;
use base 'Novel::Robot::Parser';

use File::Slurp qw/read_file/;
use Data::MessagePack;
#use utf8;

sub parse_novel {
    my ($self, $raw_file) = @_;
    $raw_file = $raw_file->[0] if(ref($raw_file) eq 'ARRAY');
    my $s = read_file( $raw_file, binmode => ':raw' ) ;
    my $mp = Data::MessagePack->new();
    $mp->utf8(0);
    my $up = $mp->unpack($s);
    return $up;
}

1;
