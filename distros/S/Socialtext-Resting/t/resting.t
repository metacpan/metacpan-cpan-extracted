use Test::More;
use IPC::Run;

use strict;
use warnings;

# Put the page
Setup: {
    eval { require Socialtext::Resting::Getopt };
    if ($@) {
        plan skip_all => 'No Socialtext::Resting::Getopt';
        exit;
    }

    Socialtext::Resting::Getopt->import('get_rester');

    my $r = get_rester(workspace => 'st-rest-test');
    eval { $r->put_page("Test page", "This is a\nfile thing here\n")};
    if ($@) {
        plan skip_all => 'No access to socialtext server';
    }
    else {
        plan tests => 21;
    }
}

Stuff: {
    my $r = get_rester(workspace => 'st-rest-test');
    # Get it back and check it
    my $content = $r->get_page("Test page");

    like ($content, qr/file thing here/, 
            'Content has both lines');

    # Put 2 attachments
    my $text_content = readfile("t/filename.txt");
    my $jpg_content  = readfile("t/file.jpg");
    my $text_id = $r->post_attachment(
            "Test page", "filename.txt", $text_content, "text/plain");
    my $jpeg_id = $r->post_attachment(
            "Test page", "file.jpg", $jpg_content, "image/jpeg");

    my $retrieved_text = $r->get_attachment($text_id);
    my $retrieved_jpeg = $r->get_attachment($jpeg_id);
    is ($text_content, $retrieved_text, "text attachment roundtrips");
    is ($jpg_content, $retrieved_jpeg, "jpeg attachment roundtrips");

    # Set a tag or two
    $r->put_pagetag("Test page", "Taggy");
    $r->put_pagetag("Test page", "Taggity tag");
    my $tags = join (' ', $r->get_pagetags("Test page"));

    like( $tags, qr/Taggity tag/, "Tag with spaces included");

    my @tagged_pages = $r->get_taggedpages('Taggy');
    is( $tagged_pages[0], 'Test page',
        'Test pages is listed in Taggy pages' );

    my $tagged_pages = $r->get_taggedpages('Taggy');
    like( $tagged_pages, qr/^Test page/,
        "Collection methods behave smart in scalar context" );
}

Get_homepage: {
    my $r = get_rester(workspace => 'st-rest-test');
    is $r->get_homepage, 'rest_test', 'get homepage';
}

Invalid_workspace: {
    my $r = get_rester(workspace => 'st-no-existy');
    is $r->get_homepage, undef, 'homepage of invalid workspace';
}

Get_user: {
    my $r = get_rester(workspace => 'st-rest-test');
    my $user = $r->get_user($r->username);
    is $user->{email_address}, $r->username, 'get_user';
}

Get_user_photo: {
    my $r = get_rester(workspace => 'st-rest-test');
    my $photo = $r->get_profile_photo($r->username);
    ok $photo, 'Has photo';

    my $large = $r->get_profile_photo($r->username, 'large');
    my $medium = $r->get_profile_photo($r->username, 'medium');
    my $small = $r->get_profile_photo($r->username, 'small');

    ok length $large > length $medium, 'Large photo is bigger than the medium';
    ok length $medium > length $small, 'Medium photo is bigger than the small';
}

Get_workspace: {
    my $r = get_rester(workspace => 'st-rest-test');
    $r->accept('perl_hash');
    my $wksp = $r->get_workspace();
    is $wksp->{name}, 'st-rest-test', 'get current workspace';
    $wksp = $r->get_workspace('help');
    is $wksp->{name}, 'help-en', 'get other workspace';
    $wksp = $r->get_workspace();
    is $wksp->{name}, 'st-rest-test', 'get current workspace';
}

Get_TagHistory: {
    my $r = get_rester(workspace => 'st-rest-test');
    $r->put_pagetag("Test page", "Tag 1");
    $r->put_pagetag("Test page", "Tag 2");

    my $history = $r->get_taghistory('Test page');
    like($history, qr/Tags:.*Tag 1/, 'Has tag history');
}

Name_to_id: {
    my $r = get_rester(workspace => 'st-rest-test');
    is $r->name_to_id('Water bottle'), 'water_bottle', 'name_to_id';
    is Socialtext::Resting::name_to_id('Water bottle'), 'water_bottle',
        'name_to_id';
}

Perl_hash_accept_type: {
    my $r = get_rester(workspace => 'st-rest-test');
    $r->accept('perl_hash');
    isa_ok scalar($r->get_page('Test Page')), 'HASH';
    isa_ok scalar($r->get_pagetags('Test Page')), 'ARRAY';
    isa_ok scalar($r->get_taggedpages('Taggy')), 'ARRAY';
}

exit;

sub readfile {
    my ($filename) = shift;
    if (! open (NEWFILE, $filename)) {
        print STDERR "$filename could not be opened for reading: $!\n";
        return;
    }
    local $/;
    my $data = <NEWFILE>;
    close (NEWFILE);

    return ($data);
}
