package Plift::Handler::Render;

use Moo;
use Carp;


sub register {
    my ($self, $engine) = @_;

    $engine->add_handler({
        name      => 'render',
        tag       => 'x-render',
        attribute => ['data-render'],
        handler   => \&create_directives
    });
}


sub create_directives {
    my ($element, $ctx) = @_;
    my $node = $element->get(0);

    # walk directive stack, get node id
    $ctx->rewind_directive_stack($element);

    # parse directive
    my $is_tag = $node->localname eq 'x-render';
    my $render_instruction = $node->getAttribute($is_tag ? 'data' : 'data-render');
    $node->removeAttribute('data-render') unless $is_tag;

    # prepare selector
    my $element_selector = $ctx->selector_for($node);

    # data-render="[datapoint]" (step into directive)
    if ($render_instruction =~ /^\s*\[\s*([\w._-]+)\s*\]\s*$/) {

        # modifiers
        my $mod = $ctx->_parse_matchspec_modifiers($render_instruction);
        $element_selector = '^'.$element_selector
            if $mod->{replace} || $is_tag;

        # push directive stack
        $ctx->push_at($element_selector, $1);
    }

    # data-render="datapoint"
    else {

        foreach my $instruction (split /\s+/, $render_instruction) {

            my $mod = $ctx->_parse_matchspec_modifiers($instruction);
            my ($data_point, $attribute) = split '@', $instruction;
            my $selector = $element_selector;
            $selector .= "\@$attribute" if defined $attribute;
            $selector .= '+' if $mod->{append};
            $selector = '+'.$selector if $mod->{prepend};
            $selector = '^'.$selector if $mod->{replace} || $is_tag;

            $ctx->at($selector, $data_point);
       }
    }
}








1;

__END__

=encoding utf-8

=head1 NAME

Plift::Handler::Render - Render data referenced in templates.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
