# 01basic.t -- ...
#
# $Id: 01basic.t,v 1.2 2004/11/07 02:21:22 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

can_ok($p, qw/
    handler
    show_open_entities
    show_open_elements
    show_error_numbers
    output_comment_decls
    output_marked_sections
    output_general_entities
    map_catalog_document
    restrict_file_reading
    warnings
    catalogs
    search_dirs
    include_params
    active_links

    parse

    split_message

    pass_file_descriptor
    parse_string
/);

