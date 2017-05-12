#$Id: 05_formating.t 397 2009-01-18 14:21:47Z zag $

=pod

Test  Pod::ToDocBook::DoSequences filter

=cut

use strict;
use warnings;
#use Test::More ('no_plan');
use Test::More tests => 9;
use XML::ExtOn qw( create_pipe );
use XML::SAX::Writer;
use XML::Flow;
use Data::Dumper;
use_ok 'Pod::ToDocBook::Pod2xml';
use_ok 'Pod::ToDocBook::ProcessHeads';
use_ok 'Pod::ToDocBook::DoSequences';

sub pod2xml {
    my $text = shift;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe(
        $px, qw( Pod::ToDocBook::DoSequences ),

        #      create_pipe( $px,
        $w
    );
    $p->parse($text);
    return $buf;
}

my $xml1 = pod2xml( <<'OUT1' );
=pod

asd B<bold> asdasd I<italic> asdasd C<code> F<filename>
S<text> X<topicname> Z<null format> 

 Codes in verbatim B<bold> asdasdasd 

=cut
OUT1

# Looks like you failed 1 test of 6.
# <chapter><pod><para>asd <emphasis role='bold'>bold</emphasis> asdasd <emphasis role='italic'>italic</emphasis> asdasd <literal role='code'><![CDATA[code]]></literal>  <filename>filename</filename>
#  <indexterm><primary>topicname</primary></indexterm> null format</para><verbatim><![CDATA[ Codes in verbatim B<bold> asdasdasd
#
# ]]></verbatim></pod></chapter>

my ( $t1, $c1 );
( new XML::Flow:: \$xml1 )->read(
    {
        'para' => sub {
            shift;
            $c1++;
            $t1 = [ grep { ref($_) } @_ ];
        },
        'emphasis' =>
          sub { my $a = shift; $c1++ if $a->{role}; return { emphasis => @_ } },
        'literal' =>
          sub { my $a = shift; $c1++ if $a->{role}; return { literal => @_ } },
        'filename' => sub { my $a = shift; $c1++; return { filename => @_ } },
        'indexterm' => sub { shift; $c1++; { indexterm => @_ } },
        'primary'   => sub { shift; $c1++; { primary   => @_ } },
        term => sub { shift; return term => join "", @_ }
    }
);
is $c1, 7, 'format codes: count';
is_deeply $t1,
  [
    { 'emphasis'  => 'bold' },
    { 'emphasis'  => 'italic' },
    { 'literal'   => 'code' },
    { 'filename'  => 'filename' },
    { 'indexterm' => { 'primary' => 'topicname' } }
  ],
  'format codes: struct';

my $xml2 = pod2xml( <<'OUT2' );

=pod

E<Escape> 

Rt S<$x ? $y : $z> 

Test for escape E<amp> E<0x20>

=cut
OUT2

ok !$@, 'ecapes';

my $xml3 = pod2xml( <<'OUT3' );
=pod

L<text|http://www.ru>
L<http://www.ru>

=cut
OUT3

# <chapter><pod><para><ulink url='http://www.ru'>text</ulink>
# <ulink url='http://www.ru'>http://www.ru</ulink></para></pod></chapter>

my ( $t3, $c3 );
( new XML::Flow:: \$xml3 )->read(
    {
        para => sub { shift; $t3 = \@_ },
        ulink => sub { my $a = shift; ulink => $a }
    }
);

is_deeply $t3,
  [
    'ulink', { 'url' => 'http://www.ru' },
    'ulink', { 'url' => 'http://www.ru' }
  ],
  'external link';

my $xml4 = pod2xml( <<'OUT3' );
=pod

L<text|/"section1">
L<"section2">
L<text|somedoc/"section3">

=cut
OUT3

# <chapter><pod><para><link linkend=':section1'><quote>text</quote></link>
# <link linkend=':section2'><quote>section2</quote></link>
# <link linkend='somedoc:section3'><quote>text</quote></link></para></pod></chapter>

my ( $t4, $c4 );
( new XML::Flow:: \$xml4 )->read(
    {
        para => sub { shift; $t4 = \@_ },
        link => sub { my $a = shift; link => $a }
    }
);
is_deeply $t4,
  [
    'link', { 'linkend' => ':section1' },
    'link', { 'linkend' => ':section2' },
    'link', { 'linkend' => 'somedoc:section3' }
  ],
  'enternal link';

my $xml5 = pod2xml( <<'OUT3' );
=pod

L<ls(1)>

=cut
OUT3

# <chapter><pod><para><citerefentry><refentrytitle>ls</refentrytitle><manvolnum>1</manvolnum></citerefentry></para></pod></chapter>
my ( $t5, $c5 );
( new XML::Flow:: \$xml5 )->read(
    {
        citerefentry  => sub { $c5++ },
        refentrytitle => sub { $c5++ },
        manvolnum     => sub { $c5++ }
    }
);
is $c5, 3, 'man link';

