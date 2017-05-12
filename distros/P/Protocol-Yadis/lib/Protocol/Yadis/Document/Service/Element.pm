package Protocol::Yadis::Document::Service::Element;

use strict;
use warnings;

use overload '""' => sub { shift->to_string }, fallback => 1;

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    $self->{name}    ||= '';
    $self->{content} ||= '';
    $self->{attrs}   ||= [];

    return $self;
}

sub name    { defined $_[1] ? $_[0]->{name}    = $_[1] : $_[0]->{name} }
sub content { defined $_[1] ? $_[0]->{content} = $_[1] : $_[0]->{content} }
sub attrs   { defined $_[1] ? $_[0]->{attrs}   = $_[1] : $_[0]->{attrs} }

sub attr {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;

    my $attrs = $self->attrs;

    my $i = 0;
    for (; $i < @$attrs; $i += 2) {
        last if $attrs->[$i] eq $name;
    }

    if ($value) {
        if ($i >= @$attrs) {
            push @$attrs, ($name => $value);
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

    my $name = $self->name;
    return '' unless $name;

    my $attrs = '';
    for (my $i = 0; $i < @{$self->attrs}; $i += 2) {
        $attrs .= ' ';
        $attrs .= $self->attrs->[$i] . '="' . $self->attrs->[$i + 1] . '"';
    }
    my $content = $self->content;

    return "<$name$attrs>$content</$name>";
}

1;
__END__

=head1 NAME

Protocol::Yadis::Document::Service::Element - Protocol::Yadis::Document::Service element object

=head1 SYNOPSIS

    my $e = Protocol::Yadis::Document::Service::Element->new;

    $e->name('Type');
    $e->attrs([a => 'b', c => 'd']);
    $e->content('foo');

    # <Type a="b" c="d">foo</Type>

=head1 DESCRIPTION

This is an element object for L<Protocol::Yadis::Document::Service>.

=head1 ATTRIBUTES

=head2 C<name>

Element name.

=head2 C<content>

Element content.

=head1 METHODS

=head2 C<new>

Creates a new L<Protocol::Yadis::Document::Service::Element> instance.

=head2 C<attrs>

Sets/gets element attributes.

=head2 C<attr>

Sets/gets element attribute.

=head2 C<to_string>

String representation.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2009, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
