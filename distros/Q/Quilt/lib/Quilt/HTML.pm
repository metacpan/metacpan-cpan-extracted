#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: HTML.pm,v 1.4 1997/11/03 17:46:46 ken Exp $
#

use Class::Visitor;

use strict;

visitor_class 'Quilt::HTML', 'Quilt', {};

visitor_class 'Quilt::HTML::Title', 'Quilt', {
    contents => '@',
    id => '$',
    level => '$',
    quadding => '$',
};

visitor_class 'Quilt::HTML::Pre', 'Quilt::Flow', {};
visitor_class 'Quilt::HTML::NoFill', 'Quilt::Flow', {};
visitor_class 'Quilt::HTML::List', 'Quilt::Flow', {
    type => '$',
    continued => '$',
};
visitor_class 'Quilt::HTML::List::Item', 'Quilt::Flow', {};
visitor_class 'Quilt::HTML::List::Term', 'Quilt::Flow', {};
visitor_class 'Quilt::HTML::Anchor', 'Quilt::Flow', {
    url => '@',
};

visitor_class 'Quilt::HTML::Table', 'Quilt::Flow', {
    frame => '$',
};
visitor_class 'Quilt::HTML::Table::Row', 'Quilt::Flow', {};
visitor_class 'Quilt::HTML::Table::Data', 'Quilt::Flow', {};

1;
