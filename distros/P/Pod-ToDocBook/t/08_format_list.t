#$Id: 08_format_list.t 695 2010-01-18 17:48:33Z zag $

=pod

Test  Pod::ToDocBook::FormatList filter

=cut

use strict;
use warnings;
#use Test::More ('no_plan');
use Test::More tests => 6;
use XML::ExtOn qw( create_pipe );
use XML::SAX::Writer;
use XML::Flow;
use Data::Dumper;
use_ok 'Pod::ToDocBook::Pod2xml';
use_ok 'Pod::ToDocBook::ProcessHeads';
use_ok 'Pod::ToDocBook::DoSequences';
use_ok 'Pod::ToDocBook::FormatList';
use_ok 'Pod::ToDocBook::ProcessItems';


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

sub is_deeply_xml1 {
    my ( $got_xml, $expected_xml, @p ) = @_;
    return is_deeply( xml_ref($got_xml), xml_ref($expected_xml), @p );
}

sub pod2xml {
    my $text = shift;
    my $buf;
    my $w = new XML::SAX::Writer:: Output => \$buf;
    my $px = new Pod::ToDocBook::Pod2xml:: header => 0, doctype => 'chapter';
    my $p = create_pipe(
        $px,'Pod::ToDocBook::FormatList','Pod::ToDocBook::ProcessItems',
        $w 
    );
    $p->parse($text);
    return $buf;
}

my $xml1 = pod2xml( <<'OUT1' );

=pod

=begin list

- item 1
- item 2
- item 3

=end list

=head1 title

=over 1

=item * tes2

=back

=cut
OUT1

is_deeply_xml  $xml1,
q# <chapter><pod><itemizedlist><listitem><para>item 1</para></listitem><listitem><para>item 2</para></listitem><listitem><para>item 3</para></listitem></itemizedlist><head1><title>title</title><itemizedlist><listitem><para>tes2</para></listitem></itemizedlist></head1></pod></chapter>#,'format codes: count';

