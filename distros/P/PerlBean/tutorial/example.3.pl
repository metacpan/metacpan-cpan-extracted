#!/usr/bin/perl

use strict;
use PerlBean::Style;

my $style = PerlBean::Style->instance();

$style->set_method_factory_name_to_method_base_filter(\&mbase_flt);
$style->set_method_operation_filter(\&op_ftl);
$style->set_str_pre_block_open_curl("\n__IND_BLOCK__");
$style->set_str_between_function_and_parenthesis(' ');
$style->set_indent("\t");

require 'example.1.pl';

sub mbase_flt {
    my $ret = '';
    foreach my $attr_part ( split(/_+/, shift) ) {
        $ret .= ucfirst($attr_part);
    }
    return($ret);
}

sub op_ftl {
    return( ucfirst(shift) );
}


