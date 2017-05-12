package Template::Refine::Processor::Rule::Select::CSS;
use Moose;
use HTML::Selector::XPath qw(selector_to_xpath);
extends 'Template::Refine::Processor::Rule::Select::XPath';

sub _xpath {
    my $self = shift;
    return selector_to_xpath($self->pattern);
}

1;
