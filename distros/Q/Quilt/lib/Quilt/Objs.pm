package Quilt::Objs;

use Class::Visitor;

use strict;

visitor_class 'Quilt', 'Class::Visitor::Base', {};

visitor_class 'Quilt::Flow', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
    inline => '$',
    is_mark => '$',		# XXX hack, hack, hack
    lines => '$',
    quadding => '$',
    first_line_start_indent => '$',
    start_indent => '$',
    end_indent => '$',
    space_before => '$',
    space_after => '$',
};

visitor_class 'Quilt::DO::Document', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
    title => '@',
    subtitle => '@',
    authors => '@',
    abstract => '@',
    date => '@',
};

visitor_class 'Quilt::DO::Struct::Section', 'Quilt::Flow', {
    title => '@',
    subtitle => '@',
    type => '$',
};

visitor_class 'Quilt::DO::Struct::Formal', 'Quilt::Flow', {
    title => '@',
    subtitle => '@',
    type => '$',
};

visitor_class 'Quilt::DO::Struct::Admonition', 'Quilt::DO::Struct::Formal', {};
visitor_class 'Quilt::DO::Struct::Bridge', 'Quilt::Flow', {};

visitor_class 'Quilt::DO::List', 'Quilt::Flow', {
    type => '$',
    continued => '$',
};

# lines:                   wrap*, asis
# quadding:                start*, end, center, justify
# first-line-start-indent: (0pt*)
# start-indent:            (0pt*)
# end-indent:              (0pt*)
# space-before:            (0pt*)
# space-after:             (0pt*)
visitor_class 'Quilt::Flow::Paragraph', 'Quilt::Flow', {
};

visitor_class 'Quilt::DO::Block::Paragraph', 'Quilt::Flow', {};
visitor_class 'Quilt::DO::List::Item', 'Quilt::Flow', {};
visitor_class 'Quilt::DO::List::Term', 'Quilt::Flow', {};

visitor_class 'Quilt::DO::Author', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
    formatted_name => '@',
    family_name => '@',
    given_name => '@',
    other_name => '@',
    title => '@',
    org_unit => '@',
    org_name => '@',
    org_name_abbr => '@',
    postoffice_address => '@',
    street => '@',
    locality => '@',
    region => '@',
    postal_code => '@',
    country => '@',
    email => '@',
    url => '@',
    blurb => '@',
};

visitor_class 'Quilt::DO::Inline', 'Quilt::Flow', {};
visitor_class 'Quilt::DO::Inline::Quote', 'Quilt::DO::Inline', {};
visitor_class 'Quilt::DO::Inline::Emphasis', 'Quilt::DO::Inline', {};
visitor_class 'Quilt::DO::Inline::Literal', 'Quilt::DO::Inline', {};
visitor_class 'Quilt::DO::Inline::Replaceable', 'Quilt::DO::Inline', {};
visitor_class 'Quilt::DO::Inline::Package', 'Quilt::DO::Inline', {};
visitor_class 'Quilt::DO::Inline::Index', 'Quilt::DO::Inline', {};

visitor_class 'Quilt::DO::Block', 'Quilt::Flow', {};
visitor_class 'Quilt::DO::Block::Screen', 'Quilt::DO::Block', {};
visitor_class 'Quilt::DO::Block::Quote', 'Quilt::DO::Block', {};
visitor_class 'Quilt::DO::Block::NoFill', 'Quilt::DO::Block', {};
visitor_class 'Quilt::DO::Block::Line', 'Quilt::DO::Block', {};

visitor_class 'Quilt::DO::XRef', 'Quilt', {};
visitor_class 'Quilt::DO::XRef::URL', 'Quilt::Flow', {
    url => '$',
};
visitor_class 'Quilt::DO::XRef::End', 'Quilt::Flow', {
    link => '$',
};
visitor_class 'Quilt::DO::XRef::Anchor', 'Quilt', {
    id => '$',
    generated_id => '$',
};

visitor_class 'Quilt::Flow::DisplaySpace', 'Quilt', {
    space => '$',
    priority => '$',
};

visitor_class 'Quilt::Flow::Table', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
    frame => '$',
    colsep => '$',
    rowsep => '$',
    page_wide => '$',
};

visitor_class 'Quilt::Flow::Table::Part', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
    type => '$',
};
visitor_class 'Quilt::Flow::Table::Row', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
};
visitor_class 'Quilt::Flow::Table::Cell', 'Quilt', {
    contents => '@',
    id => '$',
    generated_id => '$',
};

package Quilt::Flow::Display;
package Quilt::Flow::Paragraph;
package Quilt::Flow::Inline;
package Quilt::HTML;
package Quilt::HTML::Title;
package Quilt::HTML::Pre;
package Quilt::HTML::List;
package Quilt::HTML::ListItem;

1;
