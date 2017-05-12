use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

use Template::Refine::Fragment;
BEGIN {
    use_ok('Template::Refine::Utils', qw(simple_replace replace_text));
}

my $f = Template::Refine::Fragment->new_from_string('<p>Hello</p>');
isa_ok $f, 'Template::Refine::Fragment';

my $out;

lives_ok {
    $out = $f->process(
        simple_replace {
            my $n = shift;
            replace_text $n, 'Goodbye'
        } '//p',
    )->render;
} 'process / replace / text / render stage lives';

is $out, '<p>Goodbye</p>', 'replace worked';
