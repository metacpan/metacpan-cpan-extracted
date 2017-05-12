#$Id: 03_itemslist.t 695 2010-01-18 17:48:33Z zag $

=pod

Test  Pod::ToDocBook::ProcessItems filter

=cut

use strict;
use warnings;

use Test::More ( tests => 12 );
use XML::ExtOn qw( create_pipe );
use XML::SAX::Writer;
use XML::Flow;
use Data::Dumper;
use_ok 'Pod::ToDocBook::Pod2xml';
use_ok 'Pod::ToDocBook::ProcessItems';
use_ok 'Pod::ToDocBook';

sub xml_ref {
    my $xml = shift;
    my %tags;

    #collect tags names;
    map { $tags{$_}++ } $xml =~ m/<(\w+)/gis;

    #make handlers
    our $res;
    for ( keys %tags ) {
        my $name = $_;
        $tags{$_} = sub {
            my $attr = shift || {};
            return $res = {
                name    => $name,
                attr    => $attr,
                content => [ grep { ref $_ } @_ ]
            };
          }
    }
    my $rd = new XML::Flow:: \$xml;
    $rd->read( \%tags );
    $res;

}

sub is_deeply_xml {
    my ( $got_xml, $expected_xml, @p ) = @_;
    unless (  is_deeply( xml_ref($got_xml), xml_ref($expected_xml), @p ) ) {
        diag "got:", "<" x 40;
        diag $got_xml;
        diag "expected:", ">" x 40;
        diag $expected_xml;

    }
}

sub pod2xml {
    my $text = shift;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe(
        $px, qw( Pod::ToDocBook::ProcessItems ), @_,

        $w
    );
    $p->parse($text);
    return $buf;
}

my $xml01 = pod2xml( <<TT);

=pod

=over 1

=item * swrasr

=item * asdasd

=back

=begin list

* test1
* test2

=end list

=cut
TT

is_deeply_xml $xml01,
q#<chapter><pod><itemizedlist><listitem><para>swrasr</para></listitem><listitem><para>asdasd</para></listitem></itemizedlist><begin params='' name='list'><![CDATA[* test1
* test2

]]></begin></pod></chapter>#, 'test list';

my $xml1 = pod2xml( <<OUT1 );

=over 

=item test

test

=item test2

test

=cut

OUT1

is_deeply_xml $xml1,
q#<chapter><variablelist><varlistentry><term>test</term><listitem><para>test</para></listitem></varlistentry><varlistentry><term>test2</term><listitem><para>test</para></listitem></varlistentry></variablelist></chapter>#,
  'variablelist: terms';

my $xml2 = pod2xml( <<OUT1 );

=over 1

text

=item * test

asdasdasd

=item * test2

asdasdasd

=back

=cut

OUT1

my $f2 = new XML::Flow:: \$xml2;
my ( $t2, $c2 );
$f2->read(
    {
        'itemizedlist' => sub { shift; $c2++; $t2 = \@_ },
        'listitem' => sub { shift; $c2++; return {@_} },
        para => sub { shift; return para => join "", @_ }
    }
);
is $c2, 3, 'itemizedlist: count';

is_deeply $t2,
  [ { 'para' => 'asdasdasd' }, { 'para' => 'asdasdasd' } ],
  'itemizedlist: paras';

my $xml3 = pod2xml( <<OUT1 );

=over 1

text

=item 1 test

asdasdasd

=back

=cut

OUT1

my $f3 = new XML::Flow:: \$xml3;
my ( $t3, $c3 );
$f3->read(
    {
        'orderedlist' => sub {
            my $attr = shift;
            $c3++;
            $c3++ if exists $attr->{numeration};
            $t3 = \@_;
        },
        'listitem' => sub { shift; $c3++; return {@_} },
        para => sub { shift; return para => join "", @_ }
    }
);
is $c3, 3, 'orderedlist: count';

is_deeply $t3, [ { 'para' => 'asdasdasd' } ], 'orderedlist: para';
my $xml4 = pod2xml( <<OUT1 );

=over 1

=item test

text

=item asdasdasd

dfsdfas 

=back

=cut

OUT1

is_deeply_xml $xml4,
q# <chapter><variablelist><varlistentry><term>test</term><listitem><para>text</para></listitem></varlistentry><varlistentry><term>asdasdasd</term><listitem><para>dfsdfas</para></listitem></varlistentry></variablelist></chapter>#,
  'variablelist: struct';

my $xml5 = pod2xml( <<OUT1 );

=over 1

test

  text

=back

=cut

OUT1

# <chapter><blockquote><para>test</para></blockquote><verbatim><![CDATA[  text
# ]]></verbatim></chapter>
my $f5 = new XML::Flow:: \$xml5;
my ( $t5, $c5 );
$f5->read(
    {
        'blockquote' => sub { shift; $c5++; $t5 = \@_ },
        para => sub { shift; $c5++; return para => join "", @_ }
    }
);
is $c5, 2, 'blockqoute: count';
is_deeply $t5, [ 'para', 'test' ], 'blockqoute: struct';

