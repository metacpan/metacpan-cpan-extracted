#$Id: 07_links.t 487 2009-02-25 19:35:37Z zag $

=pod

Test  Pod::ToDocBook::DoSequences filter. Check links L

=cut

use strict;
use warnings;
#use Test::More ('no_plan');
use Test::More tests => 4;
use XML::ExtOn qw( create_pipe );
use XML::SAX::Writer;
use XML::Flow;
use Data::Dumper;
use_ok 'Pod::ToDocBook::Pod2xml';
use_ok 'Pod::ToDocBook::DoSequences';
use_ok 'Pod::ToDocBook::TableDefault';

sub pod2xml {
    my $text = shift;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter', base_id=>"test";
    my $p = create_pipe(
        $px, qw( 
        ),
        $w 
#         Pod::ToDocBook::DoSequences  

    );
    $p->parse($text);
    return $buf;
}

my $xml1 = pod2xml( <<'OUT1' );

=head1 test

para

=head2 test2

L<"test">

=cut

OUT1

#diag  $xml1; exit;
# <chapter><head1><title>test</title><para>para</para><head2><title>test2</title><para><code base_id='' text='test' linkto='test:test' name='L' type='pod' section='test'><![CDATA[L<"test">]]></code></para></head2></head1></chapter>

my ( $t1, $c1 );
( new XML::Flow:: \$xml1 )->read({
    code=>sub { shift; $c1++ },
});
is $c1, 1, 'link codes: count';


