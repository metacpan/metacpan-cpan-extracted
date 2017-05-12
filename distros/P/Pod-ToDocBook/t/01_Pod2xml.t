#$Id: 01_Pod2xml.t 443 2009-02-08 14:51:33Z zag $

=pod

Test  Pod::ToDocBook::Pod2xml filter

=cut

use strict;
use warnings;
#use Test::More ('no_plan');
use Test::More tests => 23;
use XML::ExtOn ('create_pipe');
use XML::SAX::Writer;
use Data::Dumper;
use XML::Flow;
use_ok 'Pod::ToDocBook';
use_ok 'Pod::ToDocBook::Pod2xml';

sub pod2xml {
    my $text = shift;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe( $px, $w );
    $p->parse($text);
    return $buf;
}

my $xml1 = pod2xml(<<T1);

=head1 level1

1

=head2 level2

2

=head3 leval3

3

=head1 level1

4
T1
my $f1 = new XML::Flow:: \$xml1;
my ( $t1, $c1 );
$f1->read(
    {
        'chapter' => sub { shift; $c1++; $t1 = \@_ },
        'head1' => sub { shift; $c1++; return head1 => \@_ },
        'head2' => sub { shift; $c1++; return head2 => \@_ },
        'head3' => sub { shift; $c1++; return head3 => \@_ },

        #        'head3' => sub { shift; return term => join "", @_ }
    }
);
is $c1, 5, 'heads: count';
is_deeply $t1,

  [ 'head1', [ 'head2', [ 'head3', [] ] ], 'head1', [] ], 'check struct';
eval {
    diag pod2xml(<<T1); };

=head1 level1

1

=head3 level3

error 3 level after 1

4
T1

ok $@, 'error head3 after head1';

my $xml2 = pod2xml( <<T2 );

=for xml <xml>

=begin xml param

content

=end xml

 verbatim
 vearbatim

para
prar

T2

my ( $t2, $c2 );
( new XML::Flow:: \$xml2 )->read(
    {
        'chapter' => sub { shift; $c2++; $t2 = \@_ },
        'verbatim' => sub { shift; $c2++; return verbatim => 1 },
        'para'     => sub { shift; $c2++; return para     => 1 },
        'begin'    => sub {
            my $attr = shift;
            $c2++;
            $c2++ if exists $attr->{name};
            $c2++ if $attr->{params};
            return begin => 1;
        },
    }
);
is $c2, 8, 'formats, para, verbatim: count';

is_deeply $t2, [ 'begin', 1, 'begin', 1, 'verbatim', 1, 'para', 1 ],
  'formats, para, verbatim: struct';
eval {
    pod2xml( <<T2 ); };

=begin xml param

content

=head1

T2

ok $@, 'error: unclosed begin';

eval {
    pod2xml( <<TI1 ); };

=item * test

TI1
ok $@, 'error1: item not in over';

eval {
    pod2xml( <<TI2 ); };

=head 2 test

=item * test

TI2
ok $@, 'error2: item not in over';

my $xml3 = pod2xml( <<T3 );

=over

test

=item * test

=item 2 test

=back

T3

# <chapter><over><para>test</para><item><title>* test</title></item><item><title>2 test</title></item></over></chapter>
my ( $t3, $c3 );
( new XML::Flow:: \$xml3 )->read(
    {
        'chapter' => sub { shift; $c3++; $t3 = \@_ },
        'over' => sub { shift; $c3++; return over => \@_ },
        'para'  => sub { $c3++; return para  => 1 },
        'title' => sub { $c3++; return title => 1 },
        'item' => sub { shift; $c3++; return item => 1 },
    }
);

is $c3, 7, 'over, item: count';
is_deeply $t3, [ 'over', [ 'para', 1, 'item', 1, 'item', 1 ] ],
  'over, item: struct';

my $xml4 = pod2xml( <<T4 );

=pod

=over

test B<code>

=back

=cut

T4

# <chapter><pod><over ><para>test <code name='B'><![CDATA[B<code>]]></code></para></over></pod></chapter>
my ( $t4, $c4 );
( new XML::Flow:: \$xml4 )->read(
    {
        'chapter' => sub { shift; $c4++; $t4 = \@_ },
        'pod'  => sub { shift; $c4++; return pod  => \@_ },
        'over' => sub { shift; $c4++; return over => \@_ },
        'para' => sub { $c4++; return para => 1 },
    }
);
is $c4, 4, 'pod,over : count';
is_deeply $t4, [ 'pod', [ 'over', [ 'para', 1 ] ] ], 'pod,over : struct';

eval {
    pod2xml( <<TO1 ); };

=pod

=back

TO1
ok $@, 'error: not closed =pod';

eval {
    pod2xml( <<TO2 ); };

=pod

=cut

=back

TO2

ok $@, 'error: =back without =over';

eval {
    pod2xml( <<TO2 ); };

=over

=item *

=head2 unexpexted

=back

TO2

ok $@, 'error: =head2 in =over';

sub parse_lpods {
    my $text = shift;
    my ( $t5, $c5 );
    my $xml5 = pod2xml($text);
    ( new XML::Flow:: \$xml5 )->read(
        {
            para => sub { shift; $t5 = \@_ },
            code => sub { my $a = shift; $c5++; { code => $a } }
        }
    );
    return ( $t5, $c5 );
}

my ( $t5, $c5 ) = parse_lpods(<<TO3 );
=pod

L<ftp://ftp.com> L<test|ftp://ftp.com>

=cut

TO3
is_deeply $t5,
  [
    {
        'code' => {
            'linkto' => 'ftp://ftp.com',
            'text'   => 'ftp://ftp.com',
            'name'   => 'L',
            'type'   => 'url'
        }
    },
    {
        'code' => {
            'linkto' => 'ftp://ftp.com',
            'text'   => 'test',
            'name'   => 'L',
            'type'   => 'url'
        }
    }
  ],
  'Links: urls';
is $c5, 2, 'Links: urls count';
my ( $t6, $c6 ) = parse_lpods(<<TO3 );
=pod

L<text>
L<text|name/"section">
L<text|/"section">
L<TEST::adasd>

=cut

TO3

is_deeply $t6,
  [
    {
        'code' => {
            'base_id' => 'text',
            'linkto'  => 'text:',
            'text'    => 'text',
            'name'    => 'L',
            'section' => '',
            'type'    => 'pod'
        }
    },
    {
        'code' => {
            'base_id' => 'name',
            'linkto'  => 'name:section',
            'text'    => 'text',
            'name'    => 'L',
            'section' => 'section',
            'type'    => 'pod'
        }
    },
    {
        'code' => {
            'base_id' => '',
            'linkto'  => ':section',
            'text'    => 'text',
            'name'    => 'L',
            'section' => 'section',
            'type'    => 'pod'
        }
    },
    {
        'code' => {
            'base_id' => 'TEST::adasd',
            'linkto'  => 'TEST::adasd:',
            'text'    => 'TEST::adasd',
            'name'    => 'L',
            'section' => '',
            'type'    => 'pod'
        }
    }
  ],
  'links: pods';
is $c6, 4, 'links: pods count';

my ( $t7, $c7 ) = parse_lpods(<<TO3 );
=pod

L<TEST::adasd(2)>

=cut

TO3

is_deeply $t7, [
           {
             'code' => {
                         'base_id' => 'TEST::adasd(2)',
                         'linkto' => 'TEST::adasd2:',
                         'text' => 'TEST::adasd(2)',
                         'name' => 'L',
                         'section' => '',
                         'type' => 'man'
                       }
           }
         ], 'Links: man';
is $c7, 1, 'Links: man count';

