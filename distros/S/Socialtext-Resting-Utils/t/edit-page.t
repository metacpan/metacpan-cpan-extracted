#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 34;
use lib 'lib';
use JSON::XS;

BEGIN {
    use_ok 'Socialtext::EditPage';
    use_ok 'Socialtext::Resting::Mock';
}

# Don't use a real editor
$ENV{EDITOR} = 't/mock-editor.pl';

Regular_edit: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    is $r->get_page('Foo')->{content}, 'MONKEY';
}

Edit_no_change: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'MONKEY');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    # relies on mock rester->get_page to delete from the hash
    is $r->get_page('Foo'), 'Foo not found';
}

Edit_with_callback: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    my $cb = sub { return "Ape\n\n" . shift };
    $ep->edit_page(page => 'Foo', callback => $cb);

    is $r->get_page('Foo')->{content}, "Ape\n\nMONKEY";
}

Edit_with_edit_summary_callback: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(
        page => 'Foo', 
        callback => sub { return "Ape\n\n" . shift },
        summary_callback => sub {'o hai'},
    );

    my $page = $r->get_page('Foo');
    is $page->{content}, "Ape\n\nMONKEY";
    is $page->{edit_summary}, 'o hai';
}

Edit_with_tag: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo', tags => 'Chimp');

    is $r->get_page('Foo')->{content}, 'MONKEY';
    is_deeply [$r->get_pagetags('Foo')], ['Chimp'];
}

Edit_with_tags: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');

    my $ep = Socialtext::EditPage->new(rester => $r);
    my $tags = [qw(one two three)];
    $ep->edit_page(page => 'Foo', tags => $tags);

    is $r->get_page('Foo')->{content}, 'MONKEY';
    is_deeply [ $r->get_pagetags('Foo') ], $tags;
}

Edit_with_collision: {
  SKIP: {
    unless (qx(which merge) =~ /merge/) {
        skip "No merge tool available", 1;
    }
    close STDIN;
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', "Monkey\n");
    $r->put_page('Foo', "Ape\n");
    $r->die_on_put(412);
    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    my $expected_page = <<EOT;
<<<<<<< YOURS
MONKEY
=======
APE
>>>>>>> NEW EDIT
EOT
    is $r->get_page('Foo')->{content}, $expected_page;
  }
}

Extraclude: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', "Monkey\n");

    # Load up a fancy faked editor that copies in an extraclude.
    my $fancy_cp = File::Temp->new();
    chmod 0755, $fancy_cp->filename;
    print $fancy_cp "#!/bin/sh\ncp t/extraclude.txt \$1\n";
    $fancy_cp->close();
    local $ENV{EDITOR} = $fancy_cp->filename;

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    is $r->get_page('Foo')->{content}, <<EOT;
Monkey
{include: [Foo Bar]}
{include: [Bar Baz]}
EOT
    is $r->get_page('Foo Bar'), "Cows\n";
    is $r->get_page('Bar Baz'), "Bears are godless killing machines\n";
}

Extralink: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', "Monkey\n");

    # Load up a fancy faked editor that copies in an extralink.
    my $fancy_cp = File::Temp->new();
    chmod 0755, $fancy_cp->filename;
    print $fancy_cp "#!/bin/sh\ncp t/extralink.txt \$1\n";
    $fancy_cp->close();
    local $ENV{EDITOR} = $fancy_cp->filename;

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    is $r->get_page('Foo')->{content}, <<EOT;
Monkey
[Foo Bar]
[Bar Baz]
EOT
    is $r->get_page('Foo Bar'), "Cows\n";
    is $r->get_page('Bar Baz'), "Bears are godless killing machines\n";
}

Extraclude_in_page_content: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', <<EOT);
Monkey
.extraclude [Foo Bar]
Cows
.extraclude
EOT
    $r->put_page('FOO BAR', '');

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(page => 'Foo');

    # $EDITOR will uc() everything
    is $r->get_page('Foo')->{content}, <<EOT;
MONKEY
.extraclude [FOO BAR]
COWS
.extraclude
EOT
    is $r->get_page('FOO BAR'), '';
}

Pull_includes: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', <<EOT);
This and
{include: [Bar]}
{include [Baz Defrens]}
EOT
    $r->put_page('Bar', "Bar page\n");
    $r->put_page('Baz Defrens', "Baz page\n");

    my $ep = Socialtext::EditPage->new(rester => $r, pull_includes => 1);
    $ep->edit_page(page => 'Foo');

    # $EDITOR will uc() everything
    is $r->get_page('Foo')->{content}, <<EOT;
THIS AND
{include: [BAR]}
{include: [BAZ DEFRENS]}
EOT
    is $r->get_page('BAR'), "BAR PAGE\n";
    is $r->get_page('BAZ DEFRENS'), "BAZ PAGE\n";
}

Edit_last_page: {
    my $r = Socialtext::Resting::Mock->new;
    my @tagged_pages = (
        { 
            modified_time => 3,
            name => 'Newer',
            page_id => 'Newer',
        },
        {
            modified_time => 1,
            name => 'Older',
            page_id => 'Older',
        },
    );
    $r->set_taggedpages('coffee', encode_json(\@tagged_pages));
    $r->put_page('Newer', 'Newer');
    $r->put_page('Older', 'Older');
    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_last_page(tag => 'coffee');

    # $EDITOR will uc() everything
    is $r->get_page('Newer')->{content}, 'NEWER';
    is $r->get_page('Older'), 'Older';
}

Edit_from_template: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Empty', 'Empty not found');
    $r->put_page('Pookie', 'Template page');
    $r->put_pagetag('Pookie', 'Pumpkin');
    $r->response->code(404);

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(
        page => 'Empty',
        template => 'Pookie',
    );

    is $r->get_page('Empty')->{content}, 'TEMPLATE PAGE';
    is_deeply [$r->get_pagetags('Empty')], ['Pumpkin'];
}

Template_when_page_already_exists: {
    my $r = Socialtext::Resting::Mock->new;
    $r->put_page('Foo', 'Monkey');
    $r->put_page('Pookie', 'Template page');
    $r->response->code(200);

    my $ep = Socialtext::EditPage->new(rester => $r);
    $ep->edit_page(
        page => 'Foo',
        template => 'Pookie',
    );

    is $r->get_page('Foo')->{content}, 'MONKEY';
}

Failed_Edit: {
    my $r = Socialtext::Resting::Mock->new;
    $r->workspace('Foo');

    # Successful edit
    my $ep = Socialtext::EditPage->new(rester => $r);

    unlink "baz.sav";
    unlink "baz.sav.1";

    {
        no warnings 'redefine';
        *Socialtext::Resting::Mock::put_page = sub { die "shoot" };
    }

    eval {
        # Failed edit
        $ep->edit_page(page => 'Baz', callback => sub {"Failed"});
    };

    ok $@, "Edit failed";
    is $r->get_page('Baz'), 'Baz not found';

    ok -f 'baz.sav', "baz.sav exists";
    is _read_file('baz.sav'), 'Failed', "content is correct";

    eval {
        # Failed edit
        $ep->edit_page(page => 'Baz', callback => sub {"Failed again"});
    };
    ok -f 'baz.sav.1', "baz.sav exists";
    is _read_file('baz.sav.1'), 'Failed again', "content is correct";
}

sub _read_file {
    my $filename = shift;
    open(my $fh, $filename) or die "unable to open $filename $!\n";
    my $new_content;
    {
        local $/;
        $new_content = <$fh>;
    }
    close $fh;
    return $new_content;
}

