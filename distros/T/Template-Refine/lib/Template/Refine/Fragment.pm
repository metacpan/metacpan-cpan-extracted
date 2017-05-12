package Template::Refine::Fragment;
use Moose;
use Moose::Util::TypeConstraints;

use XML::LibXML;
use Path::Class qw(file);
use List::Util qw(first);
use namespace::clean -except => ['meta'];

my $parser = XML::LibXML->new;
$parser->no_network(1);

class_type 'XML::LibXML::DocumentFragment';
class_type 'XML::LibXML::Node';

coerce 'XML::LibXML::DocumentFragment',
  => from 'XML::LibXML::Node',
  => via {
      my $f = XML::LibXML::DocumentFragment->new;
      $f->addChild( $_->cloneNode(1) );
      return $f;
  };

has fragment => (
    isa      => 'XML::LibXML::DocumentFragment',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

sub new_from_dom {
    my ($class, $dom) = @_;
    return $class->new(fragment => _extract_body($dom));
}

sub new_from_string {
    my ($class, $template) = @_;
    return $class->new(fragment => _parse_html($template));
}

sub new_from_file {
    my ($class, $file) = @_;
    return $class->new_from_string(file($file)->slurp);
}

sub _parse_html {
    my $template = shift;
    return _extract_body($parser->_parse_html_string($template, undef, undef, 0));
}

sub _extract_body {
    my $doc = shift;
    my $html = $doc->documentElement;
    return $html unless $html->nodeName eq 'html';

    my $body = first { $_->nodeName eq 'body' } $html->childNodes;
    confess 'error finding body' unless $body;
    my $frag = XML::LibXML::DocumentFragment->new;
    $frag->addChild($_) for $body->childNodes;
    return $frag;
}

sub _to_document {
    my $frag = shift;
    my $doc = XML::LibXML::Document->new;
    my $html = XML::LibXML::Element->new('html');
    my $body = XML::LibXML::Element->new('body');
    $doc->setDocumentElement( $html );
    $html->addChild( $body );
    $body->addChild( $frag->cloneNode(1) );
    return $doc;
}

sub process {
    my ($self, @rules) = @_;
    my $dom = _to_document($self->fragment); # make full doc so that "/" is meaningful
    $_->process($dom) for @rules;
    return $self->new_from_dom($dom);
}

sub render {
    my $self = shift;
    return $self->fragment->toString;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Template::Refine::Fragment - represent and refine a fragment of HTML

=head1 SYNOPSIS

    use Template::Refine::Fragment;
    use Template::Refine::Processor::Rule;
    use Template::Refine::Processor::Rule::Select::XPath;
    use Template::Refine::Processor::Rule::Transform::Replace::WithText;

    my $frag = Template::Refine::Fragment->new_from_string(
        '<p>Hello, <span class="world"/>.' # invalid HTML ok
    );

    my $refined = $frag->process(
        Template::Refine::Processor::Rule->new(
            selector => Template::Refine::Processor::Rule::Select::XPath->new(
                pattern => '//*[@class="world"]',
            ),
            transformer => Template::Refine::Processor::Rule::Transform::Replace::WithText->new(
                replacement => sub {
                    return 'world';
                },
            ),
        ),
    );

    return $refined->render; # "<p>Hello, <span class="world">world</span>.</p>"

=head1 METHODS

=head2 new( fragment => $fragment )

Accepts one argument, fragment, which is the
XML::LibXML::DocumentFragment that you want to operate on.

The constructors below are more useful.

=head2 new_from_dom( $dom )

Accepts an XML::LibXML::DOM object

=head2 new_from_string( $html_string )

Accepts an HTML string

=head2 new_from_file( $filename )

Accepts a filename containing HTML

=head2 fragment

Return the C<XML::LibXML::DocumentFragment> that backs this object.

=head2 process( @rules )

Apply C<Template::Refine::Processor::Rule>s in C<@rules> and return a
new C<Template::Refine::Fragment>.

=head2 render

Return the fragment as valid HTML

=head1 BUGS

Report to RT.

=head1 VERSION CONTROL

You can browse the repository at:

L<http://git.jrock.us/?p=Template-Refine.git;a=summary>

You can clone the repository by typing:

    git clone git://git.jrock.us/Template-Refine

Please e-mail me any patches.  Thanks in advance for your help!

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

    Copyright (c) 2008 Infinity Interactive. All rights reserved This
    program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

