# perl
#
# Safer Perl: Extract meta information
#
# ClassTemplate
#
# Sat Sep 27 13:50:07 2014

use warnings;
use strict;

use Data::Dumper;

use Scalar::Validation qw(:all);

# use ClassTemplate;

meta_info_clear();

# ------------------------------------------------------------------------------
my $template = build_meta_info_for_module('ClassTemplate');

ClassTemplate::no_args();
$template->add_date_positional();
$template->get_content();
$template->current_position_positional();
$template->current_position_named();
$template->current_position_at_date();
$template->special_rule_test();
$template->write();

# ------------------------------------------------------------------------------
end_meta_info_gen();

print "\n# === Meta Class Information Dump ============================\n"; 

# print Dumper(get_meta_info());

print Dumper (list_meta_info()->[1]);

