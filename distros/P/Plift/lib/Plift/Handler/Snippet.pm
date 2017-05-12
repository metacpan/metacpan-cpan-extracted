package Plift::Handler::Snippet;

use Moo;
use Carp;
use URI;
use Class::Load qw/ load_class /;

has 'attributes', is => 'ro', default => sub { [qw/ data-snippet data-plift data-plift-snippet /] };

sub register {
    my ($self, $engine) = @_;

    $engine->add_handler({
        name      => 'snippet',
        attribute => $self->attributes,
        handler   => sub {
            $self->process(@_);
        }
    })
}


sub process {
    my ($self, $element, $ctx) = @_;
    my $node = $element->get(0);

    my $snippet_uri;
    my $attr;
    foreach $attr (@{ $self->attributes }) {

        if ($node->hasAttribute($attr)) {

            $snippet_uri = URI->new($node->getAttribute($attr));
            $node->removeAttribute($attr);
        }
    }

    confess "Template error: missing snippet name in the '$attr' attribute.!"
        unless $snippet_uri->path;

    # run
    $ctx->run_snippet($snippet_uri->path, $element, { $snippet_uri->query_form });
}






1;

__END__

=encoding utf-8

=head1 NAME

Plift::Handler::Snippet - Run dynamic loaded code snippets.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
