#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Perinci::Access::Perl;
use Perinci::To::Text;

my $pa = Perinci::Access::Perl->new;
my $res = $pa->request(meta => "pl:/Perinci/Examples/");
die "Can't meta: $res->[0] - $res->[1]" unless $res->[0] == 200;
my $meta = $res->[2];
$res = $pa->request(child_metas => "pl:/Perinci/Examples/");
die "Can't child_metas: $res->[0] - $res->[1]" unless $res->[0] == 200;
my $cmetas = $res->[2];

my $doc = Perinci::To::Text->new(
    name=>"Perinci::Examples", meta=>$meta, child_metas=>$cmetas);

$doc->doc_sections([qw/a b c/]);
$doc->add_doc_section_before('j', 'a');
is_deeply($doc->doc_sections, [qw/j a b c/], 'add_doc_section_before (1)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_before('k', 'a');
is_deeply($doc->doc_sections, [qw/j k a b c/], 'add_doc_section_before (2)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_before('l', 'z');
is_deeply($doc->doc_sections, [qw/l j k a b c/], 'add_doc_section_before (3)')
    or diag explain $doc->doc_sections;

$doc->doc_sections([qw/a b c/]);
$doc->add_doc_section_after('j', 'c');
is_deeply($doc->doc_sections, [qw/a b c j/], 'add_doc_section_after (1)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_after('k', 'c');
is_deeply($doc->doc_sections, [qw/a b c k j/], 'add_doc_section_after (2)')
    or diag explain $doc->doc_sections;
$doc->add_doc_section_after('l', 'z');
is_deeply($doc->doc_sections, [qw/a b c k j l/], 'add_doc_section_after (3)')
    or diag explain $doc->doc_sections;

$doc->doc_sections([qw/a b c/]);
$doc->delete_doc_section('a');
is_deeply($doc->doc_sections, [qw/b c/], 'delete_doc_section (1)');
$doc->delete_doc_section('c');
is_deeply($doc->doc_sections, [qw/b/], 'delete_doc_section (2)');
$doc->delete_doc_section('a');
is_deeply($doc->doc_sections, [qw/b/], 'delete_doc_section (3)');

done_testing();
