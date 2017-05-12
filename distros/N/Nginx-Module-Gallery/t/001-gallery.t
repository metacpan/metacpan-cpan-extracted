#!/usr/bin/perl

=head1 001-gallery.t

Nginx::Module::Gallery

=cut

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests        => 108;
use Encode                  qw(encode_utf8 decode_utf8);
use File::Basename          qw(dirname basename);
use File::Spec::Functions   qw(catfile rel2abs);

################################################################################
# BEGIN
################################################################################

BEGIN {
    # Use utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ':encoding(UTF-8)';
    binmode $builder->failure_output, ':encoding(UTF-8)';
    binmode $builder->todo_output,    ':encoding(UTF-8)';

    note "*** Тест Nginx::Module::Gallery ***";
    use_ok 'Nginx::Module::Gallery';

    require_ok 'Digest::MD5';
    require_ok 'Mojo::Template';
    require_ok 'MIME::Base64';
    require_ok 'MIME::Types';
    require_ok 'File::Path';

}

################################################################################
# TEST
################################################################################

note 'Human values';
for my $size (qw(0 1 1000 1000000 1000000000))
{
    my $str = Nginx::Module::Gallery::_as_human_size $size;
    ($size)
        ? ok $str =~ m/^\d+\w+$/, "$size => $str"
        : ok $str == 0, "$size => $str";
}

note 'Common icons tests';
my $common_icon_path = catfile rel2abs(dirname __FILE__), '../icons/*.png';
for my $path (glob $common_icon_path)
{
    my $filename    = basename($path);
    my $value       = basename($path, '.png');

    _test_icon_params( $value =>
        Nginx::Module::Gallery::_icon_common( $value )
    );
}

note 'Mime icons tests';
my $mime_icon_path = catfile rel2abs(dirname __FILE__), '../icons/mime/*.png';
for my $path (glob $mime_icon_path)
{
    my $filename    = basename($path);
    my $value       = basename($path, '.png');

    _test_icon_params( $value =>
        Nginx::Module::Gallery::_icon_mime( $value )
    );
}
note 'Escape';
my $escaped = Nginx::Module::Gallery::_escape_path('/tmp/"ddd./');
ok !($escaped =~ m/[^\\][.'"]/), 'Path escaped';

note 'Cache images tests';
my $data_path = catfile rel2abs(dirname __FILE__), 'data/*.png';
for my $path (glob $data_path)
{
    my $name = basename($path, '.png');

    my $md5 = Nginx::Module::Gallery::_get_md5_image( $path );
    ok length $md5,             'Get image MD5: '. $md5;

    my $icon = Nginx::Module::Gallery::make_icon( $path );
    _test_icon_params( make_icon => $icon );

    my $cache = Nginx::Module::Gallery::save_icon_in_cache($path, $icon);
    SKIP:
    {
        skip 'Cache not aviable', 2 unless $cache;

        ok -f $cache,               'Icon stored in: '. $cache;
        ok -s _,                    'Icon not empty';

        _test_icon_params( save_icon_in_cache =>
            Nginx::Module::Gallery::get_icon_form_cache( $path ) );
    }
}

note 'Templates';
my $template_path = catfile rel2abs(dirname __FILE__), '../templates/*.html.ep';
for my $path (glob $template_path)
{
    my $name = basename($path, '.html.ep');
    my $template = Nginx::Module::Gallery::_template $name;

    ok length $template, "$name loaded";
}

my $css_path = catfile rel2abs(dirname __FILE__), '../templates/main.css';
ok ((-f $css_path and ! -z _), 'CSS file exists');


sub _test_icon_params
{
    my ($name, $icon) = @_;

    ok length $icon->{raw},       sprintf '%s image BASE64 data', $name;
    ok length $icon->{mime},      sprintf '%s image mime type: %s', $name,
                                    $icon->{mime};
#    ok length $icon->{width},     sprintf '%s image width: %s', $name,
#                                    $icon->{width};
#    ok length $icon->{height},    sprintf '%s image height: %s', $name,
#                                    $icon->{height};

    my $size = length $icon->{raw};
    ok $size < 16384,           sprintf '%s image < 16Kb: %s bytes',
                                $name, $size;
}
