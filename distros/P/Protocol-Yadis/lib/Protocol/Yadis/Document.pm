package Protocol::Yadis::Document;

use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

use Protocol::Yadis::Document::Service;
use Protocol::Yadis::Document::Service::Element;

use XML::LibXML;

sub new {
    my $class = shift;
    my %param = @_;

    my $self = {};
    bless $self, $class;

    $self->{_services} ||= [];

    return $self;
}

sub services {
    my $self = shift;

    if (@_) {
        $self->{_services} = [];

        return $self;
    }
    else {
        my @priority =
          grep { defined $_->attr('priority') } @{$self->{_services}};
        my @other =
          grep { not defined $_->attr('priority') } @{$self->{_services}};

        my @sorted =
          sort { $a->attr('priority') cmp $b->attr('priority') } @priority;
        push @sorted, @other;

        return [@sorted];
    }

    return $self->{_services};
}

sub parse {
    my $class = shift;
    my $document = shift;

    my $self = $class->new;

    return unless $document;

    my $parser = XML::LibXML->new;
    my $doc;
    eval {$doc = $parser->parse_string($document); };
    return if $@;

    # Get XRDS
    my $xrds = shift @{$doc->getElementsByTagName('xrds:XRDS')};
    $xrds = shift @{$doc->getElementsByTagName('XRDS')} unless $xrds;
    return unless $xrds;

    # Get /last/ XRD
    my @xrd = $xrds->getElementsByTagName('XRD');
    my $xrd = $xrd[-1];
    return unless $xrd;

    my $services = [];
    my @services = $xrd->getElementsByTagName('Service');
    foreach my $service (@services) {
        my $s =
          Protocol::Yadis::Document::Service->new(attrs =>
              [map { $_->getName => $_->getValue } $service->attributes]);

        my $elements = [];
        my @nodes = $service->childNodes;
        foreach my $node (@nodes) {
            next unless $node->isa('XML::LibXML::Element');

            my @attrs = $node->attributes;
            my $content = $node->textContent;
            $content =~ s/^\s*//s;
            $content =~ s/\s*$//s;

            my $element = Protocol::Yadis::Document::Service::Element->new(
                name    => $node->getName,
                content => $content,
                attrs   => [map { $_->getName => $_->getValue } @attrs]
            );

            push @$elements, $element;
        }

        $s->elements($elements);

        next unless $s->Type;

        push @{$self->{_services}}, $s;
    }

    return $self;
}

sub to_string {
    my $self = shift;

    my $string = '';

    $string .= '<?xml version="1.0" encoding="UTF-8"?>' . "\n";

    $string .= ' <xrds:XRDS xmlns:xrds="xri://" xmlns="xri://*(*2.0)"' . "\n";
    $string .= '     xmlns:openid="http://openid.net/xmlns/1.0">' . "\n";

    $string .= " <XRD>\n";

    foreach my $service (@{$self->services}) {
        $string .= $service->to_string;
    }

    $string .= " </XRD>\n";
    $string .= "</xrds:XRDS>\n";

    return $string;
}

1;
__END__

=head1 NAME

Protocol::Yadis::Document - Protocol::Yadis document object

=head1 SYNOPSIS

    my $d = Protocol::Yadis::Document->parse(<<EOD);
        <?xml version="1.0" encoding="UTF-8"?>
        <xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
         <XRD>
          <Service>
           <Type> http://lid.netmesh.org/sso/2.0 </Type>
          </Service>
          <Service>
           <Type> http://lid.netmesh.org/sso/1.0 </Type>
          </Service>
         </XRD>
        </xrds:XRDS>

    my $services = $d->services;

=head1 DESCRIPTION

This is a document object for L<Protocol::Yadis>.

=head1 METHODS

=head2 C<new>

Creates a new L<Protocol::Yadis::Document> instance.

=head2 C<services>

Returns discovered Yadis services.

=head2 C<parse>

Parses XML document.

=head2 C<to_string>

String representation.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
