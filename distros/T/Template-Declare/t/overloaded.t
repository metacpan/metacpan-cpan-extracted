use warnings;
use strict;

package Wifty::UI::Element;

use overload
    '""' => sub { return shift->render },
    bool => sub { return 1 };

sub new {
    my $proto = shift;
    return bless [@_], ref($proto)||$proto;
}

sub render {
    Template::Declare->buffer->append($_[0]->[0]);
    return $_[0]->[1];
}

package Wifty::UI;
use base qw/Template::Declare/;
use Template::Declare::Tags;
use Test::More tests => 4;
require "t/utils.pl";

template element_inside_tag => sub {
    head { Wifty::UI::Element->new( qw(<ul> </ul>) ) }
};

template outs_tag => sub {
    head { outs( em {} ) }
};

template outs_element_inside_tag => sub {
    head { outs(Wifty::UI::Element->new( qw(<ul> </ul>)) ) }
};

template outs_raw_element_inside_tag => sub {
    head { outs_raw(Wifty::UI::Element->new( qw(<ul> </ul>)) ) }
};

template tag_element => sub {
    em {'xxx'} outs(Wifty::UI::Element->new( qw(<ul> </ul>)) )
};

Template::Declare->init(dispatch_to => ['Wifty::UI']);

# XXX: our obj puts directly into buffer and returns a string,
# it's higly questionable if we want escape or not
# at this point anything that put into buffer during stringification
# is not escaped, when returned string is escaped according to standard
# rules for strings:
# outs($obj) - escaped
# outs_raw($obj) - is not escaped
# tag { $obj } - is escaped

{
    Template::Declare->buffer->clear;
    my $simple =(show('element_inside_tag'));
    TODO: {
        local $TODO = "it's something we can fix, but not now";
        like($simple, qr{<head>\s*<ul>&lt;/ul&gt;\s*</head>}ms, 'head { $obj }');
    }
}

# TODO: it's questionable if we should escape tag inside outs or not.
# feel free to consider this check incorrect
{
    Template::Declare->buffer->clear;
    my $simple =(show('outs_tag'));
    like($simple, qr{<head>\s*<em></em>\s*</head>}ms, 'head { outs ( em {} ) }');
}

{
    Template::Declare->buffer->clear;
    my $simple =(show('outs_element_inside_tag'));
    like($simple, qr{<head>\s*<ul>&lt;/ul&gt;\s*</head>}ms, 'head { outs( $obj ) }');
}

{
    Template::Declare->buffer->clear;
    my $simple =(show('outs_raw_element_inside_tag'));
    like($simple, qr{<head>\s*<ul></ul>\s*</head>}ms, 'head { outs_raw( $obj ) }');
}

# TODO: this even don't work
#{
#    Template::Declare->buffer->clear;
#    my $simple =(show('tag_element'));
#    like($simple, qr{<em>xxx</em>\s*prefixsuffix\s*}ms, 'prefix before suffix');
#}

1;
