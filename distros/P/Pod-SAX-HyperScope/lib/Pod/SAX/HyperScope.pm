package Pod::SAX::HyperScope;
use strict;
use warnings;
use base 'XML::SAX::Base';
use HTML::Entities qw(encode_entities);

our $VERSION = '0.01';
our $SECTION_RX = qr/^(head\d+|para|(itemized|ordered)list|listitem)$/;
our $INLINE_RX = qr/^(I|B|C|F|X|Z|link)$/;
our $XSL_URI_DEFAULT = "/hyperscope/src/client/lib/hs/xslt/hyperscope.xsl";

sub new {
    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new(%args);
    $self->{hs} = $self->{hs_top} = $self->_new_level( text => "POD" );
    $self->{xsl_uri} = $args{xsl_uri} || $XSL_URI_DEFAULT;
    $self->{indent}  = $args{indent}  || 3;
    $self->{head_cache}->[0] = $self->{hs_top};
    $self->{ignore_markup} = 0;
    return $self;
}

sub start_document {
    my $self = shift;
}

sub end_document {
    my $self = shift;
    ${ $self->{output} } = $self->_create_opml();
}

sub start_element {
    my ( $self, $ele ) = @_;
    if ( $ele->{LocalName} =~ /^head(\d+)$/ ) {
        my $level = $1;
        $self->{hs} = $self->{head_cache}->[$level - 1];
        $self->{head_cache}->[$level] = $self->_indent();
        splice @{ $self->{head_cache} }, $level + 1;
    }
    elsif ( $ele->{LocalName} eq 'verbatim' ) {
        $self->_indent();
        $self->{hs}->{text} .= '<pre>';
    } 
    elsif ( $ele->{LocalName} =~ $SECTION_RX ) {
        $self->_indent();
    }
    elsif ( $ele->{LocalName} =~ $INLINE_RX ) {
        $self->{hs}->{text} .= $self->_inline_tag_map( $ele->{LocalName} );
    }
    elsif ( $ele->{LocalName} eq 'xlink' ) {
        my $href = $ele->{Attributes}->{'{}href'}->{Value} || "";
        $self->{hs}->{text} .= "<a href=\"$href\">";
    }
    elsif ( $ele->{LocalName} eq 'markup' ) {
        if ( $ele->{Attributes}->{'{}ordinary_paragraph'}->{Value} ) {
            $self->_indent( text => $ele->{Attributes}->{'{}type'}->{Value} );
        }
        else {
            $self->{ignore_markup} = 1;
        }
    }
}

sub end_element {
    my ( $self, $ele ) = @_;
    if ( $ele->{LocalName} =~ /^head(\d+)$/ ) {
        return;
    }
    elsif ( $ele->{LocalName} =~ $SECTION_RX ) {
        $self->_outdent();
    }
    elsif ( $ele->{LocalName} eq 'verbatim' ) {
        $self->_outdent();
        $self->{hs}->{text} .= '</pre>';
    } 
    elsif ( $ele->{LocalName} =~ $INLINE_RX ) {
        $self->{hs}->{text} .= $self->_inline_tag_map( $ele->{LocalName}, 1 );
    }
    elsif ( $ele->{LocalName} eq 'xlink' ) {
        $self->{hs}->{text} .= "</a>";
    }
    elsif ( $ele->{LocalName} eq 'markup' ) {
        $self->_outdent unless $self->{ignore_markup};
        $self->{ignore_markup} = 0;
    }
}

sub characters {
    my ( $self, $content ) = @_;
    if ( defined $content->{Data} ) {
        $self->{hs}->{text} .= encode_entities( $content->{Data} );
    }
}

sub _inline_tag_map {
    my ( $self, $pod_tag, $end ) = @_;
    my $tag = { 
        B => 'b', 
        I => 'i', 
        C => 'tt', 
        F => 'tt', 
        'link' => 'tt',
    }->{$pod_tag} || "";
    return "" unless $tag;
    return $end ? "</$tag>" : "<$tag>";
}

sub _indent {
    my ( $self, %args ) = @_;
    my $nl = $self->_new_level( parent => $self->{hs}, %args );
    push @{ $self->{hs}->{children} }, $nl;
    $self->{hs} = $nl;
    return $self->{hs};
}

sub _outdent {
    my $self = shift;
    $self->{hs} = $self->{hs}->{parent} if defined $self->{hs}->{parent};
}

sub _new_level {
    my ( $self, %args ) = @_;
    return {
        parent   => $args{parent},
        text     => $args{text},
        children => $args{children} || [],
    };
}

sub _create_opml {
    my $self    = shift;
    my $xsl_uri = $self->{xsl_uri};
    my $opml    = <<HS_START;
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet href="$xsl_uri" type="text/xsl"?>
<opml xmlns:hs="http://hyperscope.org/hyperscope/opml/public/2006/05/09" hs:version="1.0" version="2.0">
HS_START
    my $body = $self->_create_opml_body();
    $opml .= $self->_create_opml_head();
    $opml .= $body;
    $opml .= "</opml>\n";
    return $opml;
}

sub _create_opml_head {
    my $self = shift;
    my $spaces = " " x ( $self->{indent} );
    my $nid_count = $self->{nid} - 1;
    return "$spaces<head hs:nidCount=\"$nid_count\"/>\n";
}

sub _create_opml_body {
    my $self = shift;
    my $spaces = " " x ( $self->{indent} );
    $self->{nid} = 1;
    return "$spaces<body>\n"
        . $self->_make_outlines( $self->{hs_top}, 2 )
        . "$spaces</body>\n";
}

sub _make_outlines {
    my ( $self, $hs, $indent ) = @_;
    my $nid = $self->{nid}++;
    my $text    = $self->_massage_text( $hs->{text} );
    my $spaces  = " " x ( $self->{indent} * $indent );
    my $outline = "$spaces<outline hs:nid=\"0$nid\" text=\"$text\"";
    if ( @{ $hs->{children} } ) {
        $outline .= ">\n";
        for my $kid ( @{ $hs->{children} } ) {
            $outline .= $self->_make_outlines( $kid, $indent + 1 );
        }
        $outline .= "$spaces</outline>\n";
    }
    else {
        $outline .= "/>\n";
    }
    return $outline;
}

sub _massage_text {
    my ( $self, $text ) = @_;
    $text = "" unless defined $text;
    $text =~ s/\n+/<br\/>/gs;
    $text =~ s/\s*$//gs;
    $text = encode_entities($text);
    return $text;
}

1;
__END__

=pod

=head1 NAME 

Pod::SAX::HyperScope - A POD to OPML convertor for HyperScope

=head1 SYNOPSIS

    use Pod::SAX;
    use Pod::SAX::HyperScope;

    my $text = "";
    my $h = Pod::SAX::HyperScope->new( output => \$text );
    my $p = Pod::SAX->new( Handler => $h );
    $p->parse_uri('./some.pod');
    print $text;  # HyperScope OPML comes out

=head1 DESCRIPTION

This module is a SAX driver for converting SAX events generated by Pod::SAX
into OPML suitable for use by the HyperScope project
(L<http://www.hyperscope.org>).

=head1 AUTHORS

Matthew O'Connor E<lt>matthew@canonical.orgE<gt>

=head1 LICENSE

This is free software. You may use it and redistribute it under the same terms
as Perl itself.

=head1 SEE ALSO

L<Pod::SAX>, L<http://www.hyperscope.org>

=cut
