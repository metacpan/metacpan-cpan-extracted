#!/usr/bin/perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Socialtext::Resting::Mock;
use Socialtext::EditPage; # _read_file and _write_file
use File::Path qw/mkpath rmtree/;
use Fatal qw/mkpath rmtree/;
use JSON::XS;

BEGIN {
    use_ok 'Socialtext::Resting::LocalCopy';
}

# Test data
my %testdata = (
    foo => {
        json => <<'EOT',
{"page_uri":"https://www.socialtext.net/st-sandbox/index.cgi?foo","page_id":"foo","name":"Foo","wikitext":"Foocontent\n","modified_time":1188427118,"tags":["Footag"],"uri":"foo","revision_id":20070829223838,"html":"<div class=\"wiki\">\n<p>\nFoocontent</p>\n</div>\n","last_edit_time":"2007-08-29 22:38:38 GMT","last_editor":"luke.closs@socialtext.com","revision_count":15}
EOT
        tag => 'Footag',
        expected => {
            page_id => 'foo',
            name => 'Foo',
            wikitext => "Foocontent\n",
            tags => ['Footag'],
        },
    },
    bar => {
        json => <<'EOT',
{"page_uri":"https://www.socialtext.net/st-sandbox/index.cgi?bar","page_id":"bar","name":"Bar","wikitext":"Barcontent\n","modified_time":1188427118,"tags":["Bartag"],"uri":"bar","revision_id":20070829223838,"html":"<div class=\"wiki\">\n<p>\nBarcontent</p>\n</div>\n","last_edit_time":"2007-08-29 22:38:38 GMT","last_editor":"luke.closs@socialtext.com","revision_count":15}
EOT
        tag => 'Bartag',
        expected => {
            page_id => 'bar',
            name => 'Bar',
            wikitext => "Barcontent\n",
            tags => ['Bartag'],
        },
    },
);

Simple_pull_push: {
    my $data = $testdata{foo};
    my $src = _setup_rester('foo');
    my $src_lc = Socialtext::Resting::LocalCopy->new( rester => $src );
    my $tmpdir = _make_tempdir();
    $src_lc->pull(dir => $tmpdir);

    # Test that the content was saved
    _saved_ok($tmpdir, $data);

    # Push the content up to a workspace
    my $dst = Socialtext::Resting::Mock->new;
    my $dst_lc = Socialtext::Resting::LocalCopy->new( rester => $dst );
    $dst_lc->push(dir => $tmpdir);

    # Test that the workspace was populated correctly
    is $dst->get_page($data->{expected}{name}), $data->{expected}{wikitext}, 'dst wikitext';
    is_deeply [ $dst->get_pagetags($data->{expected}{name}) ], 
        $data->{expected}{tags}, 'dst tags';
}

Pull_by_tag: {
    my $data = $testdata{foo};
    my $tag = $data->{expected}{tags}[0];
    my $src = _setup_rester('foo', 'bar');
    my $src_lc = Socialtext::Resting::LocalCopy->new( rester => $src );
    my $tmpdir = _make_tempdir();
    $src_lc->pull(dir => $tmpdir, tag => $tag);

    # Test that the content was saved
    _saved_ok($tmpdir, $data);
    # Test that the other page wasn't saved
    ok !-e "$tmpdir/bar", 'bar does not exist';
}

# Note Attachment handling is not yet implemented



exit;

{
    my $dir;
    sub _make_tempdir {
        $dir = "t/localstore.$$";
        rmtree $dir if -d $dir;
        mkpath $dir;
        END { rmtree $dir if $dir and -d $dir }
        return $dir;
    }
}

sub _setup_rester {
    my $r = Socialtext::Resting::Mock->new;
    for (@_) {
        my $name = $_;
        my $data = $testdata{$name};
        $r->put_page($data->{expected}{name}, $data->{json});
        $r->put_pagetag($data->{expected}{name}, $data->{tag});
    };
    return $r;
}

sub _saved_ok {
    my $tmpdir = shift;
    my $data = shift;

    my $wikitext_file = "$tmpdir/$data->{expected}{page_id}";
    ok -e $wikitext_file, "-e $wikitext_file";
    my $json_file = "$wikitext_file.json";
    ok -e $json_file, "-e $json_file";
    my $json;
    eval { $json = decode_json( Socialtext::EditPage::_read_file($json_file) ) };
    is $@, '';
    $json->{wikitext} = Socialtext::EditPage::_read_file($wikitext_file);
    is_deeply $json, $data->{expected}, 'json object matches';
}
