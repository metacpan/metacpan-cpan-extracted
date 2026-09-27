#!/usr/bin/env perl

use strict;
use warnings;

use Docbook::Convert::Pandoc;
use Markdown::Pod::Embed;

my $markpod_or=Markdown::Pod::Embed->new({nobackup => 1});
$markpod_or->markpod_process_and_update('lib/Example.pm');

my $markdown=Docbook::Convert::Pandoc->new()->convert_file('doc/guide.xml');
print $markdown;
