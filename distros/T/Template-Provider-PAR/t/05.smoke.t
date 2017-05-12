#!perl -w -I t/lib
use strict;
use Test::More tests => 5;
use My::TestUtils;

BEGIN
{
    use_ok 'Template';
    use_ok 'Template::Provider::PAR';
}

sub generate
{
    my $message = "hello";

    my $tt_config = 
    {
     LOAD_TEMPLATES =>
     [ Template::Provider::PAR->new(ARCHIVE => shift,
                                    INCLUDE_PATH => 'templates')]
    };
    
    my $vars = 
    {
     message => $message,
    };
    
    my $template = Template->new($tt_config);

    my $output;
    $template->process(\<<TEMPLATE, $vars, \$output) or die $template->error();

[% INCLUDE included.tt %]
<<main template>>

message: "[% message %]"

TEMPLATE
    return $output;
}

# create the archive
my $zipname = 't/tmp/templates.zip';
my $zip = create_archive_ok($zipname);

#generate $zip; die;
eq_or_diff(generate($zipname), slurp('t/data/04.smoke.txt'), "generated content using zip filename");
eq_or_diff(generate($zip), slurp('t/data/04.smoke.txt'), "generated content using zip object");



1;
