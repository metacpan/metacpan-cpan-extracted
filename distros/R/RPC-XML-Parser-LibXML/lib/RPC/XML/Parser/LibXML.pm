package RPC::XML::Parser::LibXML;
use strict;
use warnings;
use 5.00800;
our $VERSION = '0.08';
use base qw/Exporter/;
use RPC::XML;
use XML::LibXML;
use MIME::Base64 ();
use Carp ();

our @EXPORT = qw/parse_rpc_xml/;

our $TYPE_MAP = +{
    int                => 'RPC::XML::int',
    i4                 => 'RPC::XML::int',
    boolean            => 'RPC::XML::boolean',
    string             => 'RPC::XML::string',
    double             => 'RPC::XML::double',
    'dateTime.iso8601' => 'RPC::XML::datetime_iso8601',
};

my $value_xpath = join "|", map "./$_", qw( int i4 boolean string double dateTime.iso8601 base64 struct array );

sub parse_rpc_xml {
    my $xml = shift;

    my $x = XML::LibXML->new({
        no_network => 1,
        expand_xinclude => 0,
        expand_entities => 1,
        load_ext_dtd => 0,
        ext_ent_handler => sub { warn "External entities disabled."; '' },
    });
    my $doc = $x->parse_string($xml)->documentElement;

    if ($doc->findnodes('/methodCall')) {
        return RPC::XML::request->new(
            $doc->findvalue('/methodCall/methodName'),
            _extract_values($doc->findnodes('//params/param/value'))
        );
    } elsif ($doc->findnodes('/methodResponse/params')) {
        return RPC::XML::response->new(
            _extract_values($doc->findnodes('//params/param/value'))
        );
    } elsif ($doc->findnodes('/methodResponse/fault')) {
        return RPC::XML::response->new(
            RPC::XML::fault->new(
                $doc->findvalue('/methodResponse/fault/value/struct/member/value/int'),
                $doc->findvalue('/methodResponse/fault/value/struct/member/value/string'),
            ),
        );
    } else {
        Carp::croak("invalid xml: $xml");
    }
}


sub _extract_values {
    my @value_nodes = @_;

    my @values;
    for my $node (grep defined, @value_nodes) {
        my($v_node) = $node->findnodes($value_xpath);
        my $value;
        if (defined $v_node) {
            $value = _extract($v_node);
        } else {
            # <value>foo</value> is treated as <string> by default
            $value = RPC::XML::string->new($node->textContent);
        }

        push @values, $value;
    }

    return @values;
}

sub _extract {
    my $node = shift;

    return unless defined $node;

    my $nodename = $node->nodeName;
    my $val = $node->textContent;
    if ($nodename eq 'base64')  {
        return RPC::XML::base64->new(MIME::Base64::decode_base64($val));
    } elsif ($nodename eq 'struct') {
        my @members = $node->findnodes('./member'); # XXX
        my $result = {};
        for my $member (@members) {
            my($name)  = $member->findnodes('./name');
            my($value) = _extract_values ($member->findnodes('./value') );
            ($result->{$name->textContent}, ) = $value;
        }
        return RPC::XML::struct->new($result);
    } elsif ($nodename eq 'array') {
        return RPC::XML::array->new(_extract_values($node->findnodes($node->nodePath . '/data/value')));
    } else {
        my $class = $TYPE_MAP->{ $nodename } or return;
        return $class->new($val);
    }
}

1;
__END__

=encoding utf8

=head1 NAME

RPC::XML::Parser::LibXML - Fast XML-RPC parser with libxml

=head1 SYNOPSIS

    use RPC::XML::Parser::LibXML;

    my $req = parse_rpc_xml(qq{
      <methodCall>
        <methodName>foo.bar</methodName>
        <params>
          <param><value><string>Hello, world!</string></value></param>
        </params>
      </methodCall>
    });
    # $req is a RPC::XML::request

=head1 DESCRIPTION

RPC::XML::Parser::LibXML is fast XML-RPC parser written with XML::LibXML.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@cpan.orgE<gt>

=head1 SEE ALSO

L<RPC::XML::Parser>, L<RPC::XML::Parser::XS>, L<XML::LibXML>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
