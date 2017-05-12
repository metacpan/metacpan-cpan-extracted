package Protocol::Yadis::Document::Service;

use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{attrs} ||= [];
    $self->{_elements} = [];

    return $self;
}

sub attrs { defined $_[1] ? $_[0]->{attrs} = $_[1] : $_[0]->{attrs} }

sub Type { shift->element('Type') }
sub URI  { shift->element('URI') }

sub element {
    my $self = shift;
    my $name = shift;
    return unless $name;

    if (my @elements = grep { $_->name eq $name } @{$self->elements}) {
        return [@elements];
    }
}

sub elements {
    my $self = shift;

    if (@_) {
        $self->{_elements} = [];

        foreach my $element (@{$_[0]}) {
            push @{$self->{_elements}}, $element;
        }
    }
    else {
        my @priority =
          grep { defined $_->attr('priority') } @{$self->{_elements}};
        my @other =
          grep { not defined $_->attr('priority') } @{$self->{_elements}};

        my @sorted =
          sort { $a->attr('priority') cmp $b->attr('priority') } @priority;
        push @sorted, @other;

        return [sort { $a->name cmp $b->name } @sorted];
    }
}

sub attr {
    my $self = shift;
    my $name = shift;
    return unless $name;

    my $attrs = $self->attrs;

    my $i = 0;
    for (; $i < @$attrs; $i += 2) {
        last if $attrs->[$i] eq $name;
    }

    if (@_) {
        my $value = shift;
        if ($i >= @$attrs) {
            push @$attrs, ($name => $value) if $value;
        }
        else {
            $attrs->[$i + 1] = $value;
        }
        return $self;
    }

    return if $i >= @$attrs;

    return $attrs->[$i + 1];
}

sub to_string {
    my $self = shift;

    my $attrs = '';
    for (my $i = 0; $i < @{$self->attrs}; $i += 2) {
        next unless $self->attrs->[$i + 1];
        $attrs .= ' ';
        $attrs .= $self->attrs->[$i] . '="' . $self->attrs->[$i + 1] . '"';
    }

    my $elements = '';
    foreach my $element (@{$self->elements}) {
        $elements .= "\n";
        $elements .= " $element";
    }
    $elements .= "\n" if $elements;

    return "<Service$attrs>$elements</Service>";
}

1;
__END__

=head1 NAME

Protocol::Yadis::Document::Service - Protocol::Yadis::Document service object

=head1 SYNOPSIS

    my $s = Protocol::Yadis::Document::Service->new;

    $s->attr(priority => 4);
    $s->elements(
        [   Protocol::Yadis::Document::Service::Element->new(
                name     => 'URI',
                content  => 'foo'
                attrs    => [priority => 0]
            ),
            Protocol::Yadis::Document::Service::Element->new(
                name     => 'URI',
                content  => 'foo'
                attrs    => [priority => 4]
            ),
            Protocol::Yadis::Document::Service::Element->new(
                name    => 'Type',
                content => 'bar'
            ),
            Protocol::Yadis::Document::Service::Element->new(
                name    => 'URI',
                content => 'baz'
            )
        ]
    );

    # <Service>
    #   <Type>foo</Type>
    #   <URI priority="0">foo</URI>
    #   <URI priority="4">foo</URI>
    #   <URI>bar</URI>
    #   <URI>baz</URI>
    # </Service>

=head1 DESCRIPTION

This is a service object for L<Protocol::Yadis::Document>.

=head1 ATTRIBUTES

=head2 C<http_req_cb>

=head1 METHODS

=head2 C<new>

Creates a new L<Protocol::Yadis::Document::Services> instance.

=head2 C<element>

Gets element by name.

=head2 C<Type>

Shortcut for getting Type element.

=head2 C<URI>

Shortcut for getting URI element.

=head2 C<elements>

Gets/sets elements.

=head2 C<attrs>

Gets/sets service attributes.

=head2 C<attr>

Gets/sets service attribute.

=head2 C<to_string>

String representation.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
