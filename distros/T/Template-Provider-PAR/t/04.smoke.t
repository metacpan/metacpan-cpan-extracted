#!perl -w -I t/lib
use strict;
use Test::More tests => 12;
use My::TestUtils;
use Template::Context;
BEGIN
{
    use_ok 'Template';
    use_ok 'Template::Provider::PAR';
}


# create the archive
my $zipname = 't/tmp/templates.zip';
my $zip = create_archive_ok($zipname);

my $ttp = Template::Provider::PAR->new(ARCHIVE => $zip,
                                       INCLUDE_PATH => 'templates');

isa_ok($ttp, 'Template::Provider::PAR');
can_ok($ttp, $_) foreach qw(fetch store load include_path paths);

is_deeply(['templates'], $ttp->include_path, "Include path ok");

# get the template
my ($doc, $error) = $ttp->fetch('included.tt');
isa_ok($doc, 'Template::Document');
eq_or_diff($doc->process(Template::Context->new), 
           slurp('t/data/templates/included.tt'), 
           "document evaluates to equal included.tt");





1;
