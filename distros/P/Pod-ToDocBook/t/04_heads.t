#$Id: 04_heads.t 487 2009-02-25 19:35:37Z zag $

=pod

Test Pod::ToDocBook::ProcessHeads filter

=cut

use strict;
use warnings;
#use Test::More ('no_plan');
use Test::More (tests=>3);

use XML::ExtOn qw( create_pipe );
use XML::SAX::Writer;
use XML::Flow;
use Data::Dumper;
use_ok 'Pod::ToDocBook::Pod2xml';
use_ok 'Pod::ToDocBook::ProcessHeads';

sub pod2xml {
    my $text = shift;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p =
      create_pipe( $px, qw( Pod::ToDocBook::ProcessHeads ),
        $w );
    $p->parse($text);
    return $buf;
}

my $xml1 = pod2xml( <<OUT1 );

=head1 sd 

=over 1

text

=item *

1

=item test2

=back

erewrwe

=over 2

=item wqwe

=item asdasdasd

=back

=over

asdasdasdasd

=back

=cut

OUT1

# <chapter><section id=':sd'><title>sd</title><over><para>text</para><item><title>*</title><para>1</para></item><item><title>test2</title></item></over><para>erewrwe</para><over><item><title>wqwe</title></item><item><title>asdasdasd</title></item></over><over><para>asdasdasdasd</para></over></section></chapter>

my ( $t4, $c4 );
( new XML::Flow:: \$xml1 )->read(
    {
        section => sub { shift; $t4 = \@_ },
        title => sub { my $a = shift; title => $a }
    }
);
is_deeply $t4, [
           'title',
           {}
         ],'section';
my $xml2 = pod2xml( <<OUT1 );

=head1 NAME

test

=cut
OUT1

