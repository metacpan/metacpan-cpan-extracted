package Plift::Handler::Meta;

use Moo;
use Carp;
use URI;
use Class::Load qw/ load_class /;


sub register {
    my ($self, $engine) = @_;

    $engine->add_handler({
        name    => 'meta',
        tag     => 'x-meta',
        handler => sub {
            $self->process(@_);
        }
    })
}


sub process {
    my ($self, $element, $ctx) = @_;
    my $node = $element->get(0);
    my $meta = $ctx->metadata;

    # name/content pair
    if ($node->hasAttribute('name') && $node->hasAttribute('content')) {

        $meta->{$node->getAttribute('name')} = $node->getAttribute('content');
    }

    # attr=value pairs
    else {

        @$meta{keys %$node} = values %$node;
    }

    $node->unbindNode;
}






1;

__END__

=encoding utf-8

=head1 NAME

Plift::Handler::Meta - Set context metadata.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
