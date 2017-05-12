use Test::More tests => 2;

use strict;
use Template;
use List::Util 'shuffle';

BEGIN {
  use_ok('Template::Plugin::SortNatural');
}

diag( "Testing Template::Plugin::SortNatural $Template::Plugin::SortNatural::VERSION" );

my $tt = Template->new || die $Template::ERROR, "\n";

my $template = "[% USE SortNatural; list.nsort.join(' ') %]";
my @list = shuffle ( 1 .. 10000 );

# compile our template
my $output = '';
$tt->process(\$template, { list => \@list }, \$output) || die $tt->error(), "\n";

# split our template back into an array
my @returned_list = split(' ', $output);
my @expected = 1 .. 10000;
is_deeply( \@returned_list, \@expected, 'Test nsort against a long list' );
