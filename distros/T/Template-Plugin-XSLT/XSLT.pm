package Template::Plugin::XSLT;
use strict;
use warnings;
use base 'Template::Plugin::Filter';
our $VERSION = '1.2';
use XML::LibXSLT;
use XML::LibXML;

sub init {
    my $self = shift;
    # TODO Consider checking file name here is inside standard Template
    # Directories (for security).
    my $file = $self->{ _ARGS }->[0]
       or return $self->error('No filename specified!');
    $self->{ _DYNAMIC } = 1;

    $self->{ parser } = XML::LibXML->new();
    $self->{ XSLT } = XML::LibXSLT->new();
    my $xml;
    eval {
        $xml = $self->{ parser }->parse_file($file);
    };
    return $self->error("Stylesheet parsing error: $@") if $@;
    return $self->error("Stylesheet parsing errored") unless $xml;

    eval { 
        $self->{ stylesheet } = 
            $self->{ XSLT }->parse_stylesheet( $xml );
    };
    return $self->error("Stylesheet not valid XSL: $@") if $@;
    return $self->error("Stylesheet parsing errored") unless $self->{stylesheet};

    return $self;
}

sub filter {
    my ($self, $text, $args, $conf) = @_;
    my $xml;

    $conf = $self->merge_config($conf); 
    eval {
        $xml = $self->{ parser }->parse_string($text);
    };
    return $self->error("XML parsing error: $@") if $@;
    return $self->error("XML parsing errored") unless $xml;

    return $self->{ stylesheet}->output_string(
        $self->{ stylesheet }->transform( $xml, %{$conf || {}} )
    );
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Template::Plugin::XSLT - Transform XML fragments into something else

=head1 SYNOPSIS

    [% USE transform = XSLT("stylesheet.xsl"); %]
    ...
    [% foo.as_xml | $transform foo = '"bar"' baz = 123 %]

=head1 DESCRIPTION

This plugin for the Template Toolkit uses C<XML::LibXSLT> to transform
a chunk of XML through a filter. If the stylesheet is not valid, or if
the XML does not parse, an exception will be raised.

You can pass parameters to the stylesheet as configuration parameters to
the filter.

=head1 AUTHOR

Oringally by Simon Cozens, C<simon@cpan.org>

Maintained by Scott Penrose, C<scott@cpan.org>

=head1 SEE ALSO

L<Template>, L<XML::LibXSLT>.

=cut
