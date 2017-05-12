use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use Silki::Test::RealSchema;

use DateTime;
use DateTime::Format::Pg;
use File::Slurp qw( read_file );
use Silki::Schema::File;
use Silki::Schema::User;
use Silki::Schema::Wiki;

my $wiki = Silki::Schema::Wiki->new( short_name => 'first-wiki' );
my $page = Silki::Schema::Page->new(
    title   => 'Front Page',
    wiki_id => $wiki->wiki_id(),
);
my $user = Silki::Schema::User->GuestUser();

{
    my $text = 'text in a file';
    my $file = Silki::Schema::File->insert(
        filename  => 'test.txt',
        mime_type => 'text/plain',
        file_size => length $text,
        contents  => $text,
        user_id   => $user->user_id(),
        page_id   => $page->page_id(),
    );

    is(
        $file->mime_type_description_for_lang('en'),
        'plain text document',
        'english lang mime type description'
    );

    is(
        $file->mime_type_description_for_lang('fr'),
        'document texte brut',
        'french lang mime type description'
    );

    is(
        $file->mime_type_description_for_lang('foo'),
        'plain text document',
        'mime type description falls back to default lang'
    );

    ok(
        !$file->is_browser_displayable_image(),
        'file is not an image that can be displayed in a browser'
    );

    ok(
        $file->is_displayable_in_browser(),
        'file is displayable in browser'
    );

    is(
        $file->thumbnail_file(),
        undef,
        'no thumbnail file unless file is a browser displayable image'
    );

    my $path = $file->file_on_disk();
    is(
        read_file( $path->stringify() ),
        $file->contents(),
        "contents of file on disk"
    );

    $file->update( contents => 'new file content' );

    $file->_clear_file_on_disk();
    $path = $file->file_on_disk();
    isnt(
        read_file( $path->stringify() ),
        $file->contents(),
        "contents of file on disk are not updated unless known to be out of date"
    );

    my $creation = DateTime->now()->add( days => 2 );
    $file->update(
        creation_datetime => DateTime::Format::Pg->format_datetime($creation)
    );

    $file->_clear_file_on_disk();
    $path = $file->file_on_disk();
    is(
        read_file( $path->stringify() ),
        $file->contents(),
        "contents of file on disk are updated if out of date"
    );
}

{
    my $text = 'foobar';

    throws_ok {
        Silki::Schema::File->insert(
            filename  => 'test.txt',
            mime_type => 'text/plain',
            file_size => length $text,
            contents  => $text,
            user_id   => $user->user_id(),
            page_id   => $page->page_id(),
        );
    }
    qr/already in use/, 'cannot insert two files of the same name on a page';

    my $page2 = Silki::Schema::Page->new(
        title   => 'Scratch Pad',
        wiki_id => $wiki->wiki_id(),
    );

    lives_ok {
        Silki::Schema::File->insert(
            filename  => 'test.txt',
            mime_type => 'text/plain',
            file_size => length $text,
            contents  => $text,
            user_id   => $user->user_id(),
            page_id   => $page2->page_id(),
        );
    }
    'can insert two files of the same name on different pages';
}

{
    my $tiff = read_file('t/share/data/test.tif');
    my $file = Silki::Schema::File->insert(
        filename  => 'test.tif',
        mime_type => 'image/tiff',
        file_size => length $tiff,
        contents  => $tiff,
        user_id   => $user->user_id(),
        page_id   => $page->page_id(),
    );

    ok(
        !$file->is_browser_displayable_image(),
        'file is not an image that can be displayed in a browser'
    );

    ok(
        !$file->is_displayable_in_browser(),
        'file is not displayable in browser'
    );

    is(
        $file->thumbnail_file(),
        undef,
        'no thumbnail file unless file is a browser displayable image'
    );
}

{
    my $jpg  = read_file('t/share/data/test.jpg');
    my $file = Silki::Schema::File->insert(
        filename  => 'test.jpg',
        mime_type => 'image/jpeg',
        file_size => length $jpg,
        contents  => $jpg,
        user_id   => $user->user_id(),
        page_id   => $page->page_id(),
    );

    ok(
        $file->is_browser_displayable_image(),
        'file is an image that can be displayed in a browser'
    );

    ok(
        $file->is_displayable_in_browser(),
        'file is displayable in browser'
    );

    my $thumbnail_file = $file->thumbnail_file();
    ok(
        -f $thumbnail_file,
        'wrote a thumbnail file'
    );
}

done_testing();
