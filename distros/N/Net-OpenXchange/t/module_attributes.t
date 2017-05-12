use Modern::Perl;
use Test::More tests => 5;
use Test::Moose;

BEGIN {
    use_ok('Net::OpenXchange');
}

# The attributes are dynamically generated based on the
# Net::OpenXchange::Module namespace. Assert that the generation works.

has_attribute_ok('Net::OpenXchange', 'calendar');
has_attribute_ok('Net::OpenXchange', 'contact');
has_attribute_ok('Net::OpenXchange', 'folder');
has_attribute_ok('Net::OpenXchange', 'user');
