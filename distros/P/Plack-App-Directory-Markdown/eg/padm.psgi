use strict;
use warnings;
use utf8;
use FindBin::libs;

use Plack::App::Directory::Markdown;

Plack::App::Directory::Markdown->new(
    root => "./tmp/",
#    tx_path => 'tmpl',
    markdown_class => 'Text::Markdown::Discount',
    markdown_ext   => '.md',
)->to_app

