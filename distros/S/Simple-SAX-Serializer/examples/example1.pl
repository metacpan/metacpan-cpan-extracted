
use strict;
use warnings;

   my $xml;

    sub xml_dataset_handler {
        unless($xml) {
            $xml = Simple::SAX::Serializer->new;
            $xml->handler('dataset', sub {
                    my ($self, $element, $parent) = @_;
                    $element->validate_attributes([],
                        {load_strategy => "INSERT_LOAD_STRATEGY", reset_sequences => undef}
                    );
                    my $attributes = $element->attributes;
                    my $children_result = $element->children_result;
                    {properties => $attributes, dataset => $children_result}
                }
            );
            $xml->handler('*', sub {
                my ($self, $element, $parent) = @_;
                my $parent_name = $parent->name;
                my $attributes = $element->attributes;
                if($parent_name eq 'dataset') {
                    my $children_result = $element->children_result || {};
                    my $parent_result = $parent->children_array_result;
                    my $result = $parent->children_result;
                    push @$parent_result, $element->name => [%$children_result, map { $_ => $attributes->{$_}} sort keys %$attributes];
                } else {
                    $element->validate_attributes([], {size_column => undef, file => undef});
                    my $children_result = $parent->children_hash_result;
                    $children_result->{$element->name} = {%$attributes};
                    my $value = $element->value(1);
                    $children_result->{content} = $value if $value;
                }
            });
        }
        $xml;
    }

