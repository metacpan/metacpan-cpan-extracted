package Serengeti::Backend::Native::HTMLElement;

use strict;
use warnings;

use JavaScript;

use Serengeti::Backend::Native::HTMLElementProperties;

sub setup_jsapi {
    my ($self, $ctx) = @_;
    
    $ctx->bind_class(
        name => "HTMLElement",
        package => "HTML::Element",
        flags => JS_CLASS_NO_INSTANCE,
        methods => {
            getAttribute => sub { shift->attr(shift); },
            find => \&Serengeti::Backend::Native::Document::find,
            findFirst => \&Serengeti::Backend::Native::Document::find_first,
            hasChildNodes => sub { scalar shift->content_list() },
        },
        getter => \&Serengeti::Backend::Native::HTMLElementProperties::get_property,
    );
}

1;