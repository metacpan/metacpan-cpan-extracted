#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Template::Stencil;

# The draft-test scenario: rendering the same template from a source
# string and from a file (with and without .tmpl inference) must be
# byte-identical, wrapper and include and all.

my $e = Template::Stencil::_engine_new('t/template', 'wrapper.tmpl',
                                       0, 1, 256);

my $src = do {
    open my $fh, '<', 't/template/loops.tmpl' or die $!;
    local $/;
    <$fh>;
};

my %data = (
    js_scripts => ['lala.js'],
    page       => { header => 'This is a header', number => [3] },
    welcome    => 'Welcome',
    items      => [
        { inner => ['one', 'two', 'three'] },
        { inner => ['four', 'five', 'six'] },
    ],
);

my $from_string = Template::Stencil::_engine_render($e, $src, \%data);
my $from_file   = Template::Stencil::_engine_render($e,
    't/template/loops', \%data);
my $from_name   = Template::Stencil::_engine_render($e, 'loops', \%data);

is($from_string, $from_file,
   'rendering from string and file should be the same');
is($from_file, $from_name, 'template_dir-relative name matches too');

# Sanity on the actual content. (The ` > ` in header.tmpl is literal
# template text, never escaped.)
like($from_string, qr/<script src="lala\.js"/, 'wrapper js loop ran');
like($from_string, qr/This is a header > 3/, 'header include ran');
like($from_string, qr/Welcome/, 'variable rendered');
like($from_string, qr/class="first"[^>]*data-item-loop="0"/,
     'loop metadata rendered');
like($from_string, qr/1 last item_loop only once/, 'last-branch ran once');

Template::Stencil::_engine_free($e);

done_testing;
