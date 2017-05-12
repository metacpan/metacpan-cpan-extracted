use strict;
use warnings;
use Test::More 0.88;

use Plack::App::DummyBox;

my $text           = 'DUMMY TEXT';
my $font_file_path = '/path/to/font/file/foo.ttf';
my $font_type      = 'ft2';

note('font option');
{
    my $box = Plack::App::DummyBox->new(
        font => +{
            file => $font_file_path,
            type => $font_type,
        },
        text => $text,
    );
    is ref($box->font), 'HASH', 'exists font option';
    is $box->font->{file}, $font_file_path, 'font file path';
    is $box->font->{type}, $font_type, 'font type';
    is $box->text, $text, 'text';
}

done_testing;
