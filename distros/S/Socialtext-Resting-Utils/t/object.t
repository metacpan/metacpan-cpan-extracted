#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 15;
use lib 'lib';

BEGIN {
    use_ok 'Socialtext::WikiObject';
    use_ok 'Socialtext::Resting::Mock';
}

my $rester = Socialtext::Resting::Mock->new;

my @pages = load_test_data();
for my $p (@pages) {
    object_ok(
        page => $p->{page}, 
        page_content => $p->{page_content},
        expected => $p->{expected},
    );
}

No_wiki_supplied: {
    eval { Socialtext::WikiObject->new };
    like $@, qr/rester is mandatory!/;
}

Deep_initial_heading: {
    object_ok(
        page => 'Test Page',
        page_content => <<'EOT',
Stuff

^^^^ Currently listening to:

A song

^^ Getting oriented

Food
EOT
        expected => { 
            headings => [
                'Currently listening to', 'Getting oriented',
            ],
            page => 'Test Page',
            rester => $rester,
            text => "Stuff\n",
            'currently listening to' => "A song\n",
            'Currently listening to' => "A song\n",
            'Getting oriented' => "Food\n",
            'getting oriented' => "Food\n",
        },
    );
}

Items_and_text: {
    object_ok(
        page => 'Test Page',
        page_content => <<'EOT',
^ Contact Info:

* Item 1
* Item 2

Other text
More text
EOT
        expected => { 
            page => 'Test Page',
            rester => $rester,
            'Contact Info' => {
                items => [ 'Item 1', 'Item 2' ],
                text => "Other text\nMore text\n",
            },
            'contact info' => {
                items => [ 'Item 1', 'Item 2' ],
                text => "Other text\nMore text\n",
            },
            headings => ['Contact Info'],
        },
    );
}

Simple_tables: {
    my $table_one = [
        [ '*Search Term*',  '*Expected Results*' ],
        [ 'foo',            q{exact:Pages containing 'foo'} ],
        [ '=foo',           q{exact:Titles containing 'foo'} ],
    ];
    my $table_two = [
        ['Spam spam spam', 'Water bottle'],
        ['whiteboards and pens', 'with smelly markers'],
    ];
    object_ok(
        page => 'Table Page',
        page_content => <<'EOT',
| *Search Term* | *Expected Results* |
| foo | exact:Pages containing 'foo' |
| =foo | exact:Titles containing 'foo' |
^ Other things:
These are some things I see:
| Spam spam spam | Water bottle |
| whiteboards and pens | with smelly markers |
EOT
        expected => { 
            page => 'Table Page',
            rester => $rester,
            table => $table_one,
            'Other things' => {
                table => $table_two,
                text => "These are some things I see:\n",
            },
            'other things' => {
                table => $table_two,
                text => "These are some things I see:\n",
            },
            headings => ['Other things'],
        },
    );
}
exit;

sub object_ok {
    my %opts = @_;
    $rester->put_page($opts{page}, $opts{page_content});

    my $o = Socialtext::WikiObject->new(
        rester => $rester, 
        page => $opts{page},
    );
    isa_ok $o, 'Socialtext::WikiObject';
    is_deeply $o, $opts{expected}, $opts{page};
}

sub load_test_data {
    my @data;
    {
        my $text = <<'EOT';
^ Theme:

Initial iteration to get the web interface up on our internal beta server.

^ People:

# lukec - 25h
# pancho - 25h

^ Story Boards:

^^ [SetupApache]

^^^ Tasks:

# install base OS on app-beta (2h)
# install latest Apache2 with mod_perl2 (2h)
# Configure Apache2 to start on boot (1h)

^^ [ModPerl HelloWorld]

^^^ Tasks:

# Create Awesome-App package with hello world handler (1h)
# Install Awesome-App package into system perl on app-beta (1h)
# Configure mod_perl2 to have Awesome::App handler (1h)

^^ [Styled Homepage]

^^^ Tasks:

# Integrate mockups into Awesome-App (1h)
# Update Awesome-App on app-beta (1h)

^ Other Information:

Details go here.

* Bullet one
* Bullet two

EOT
        # Build up the data structure in reverse, as there are several 
        # duplicate nodes
        my $theme = 'Initial iteration to get the web interface up on our '
                   . "internal beta server.\n";
        my $people = [
            'lukec - 25h',
            'pancho - 25h',
        ];
        my $setup_apache_tasks = [
            'install base OS on app-beta (2h)',
            'install latest Apache2 with mod_perl2 (2h)',
            'Configure Apache2 to start on boot (1h)',
        ];
        my $setup_apache = {
            name => '[SetupApache]',
            tasks => $setup_apache_tasks,
            Tasks => $setup_apache_tasks,
        };
        my $mod_perl_tasks = [
            'Create Awesome-App package with hello world handler (1h)',
            'Install Awesome-App package into system perl on app-beta (1h)',
            'Configure mod_perl2 to have Awesome::App handler (1h)',
        ];
        my $mod_perl = {
            name => '[ModPerl HelloWorld]',
            tasks => $mod_perl_tasks,
            Tasks => $mod_perl_tasks,
        };
        my $styled_homepage_tasks = [
            'Integrate mockups into Awesome-App (1h)',
            'Update Awesome-App on app-beta (1h)',
        ];
        my $styled_homepage = {
            name => '[Styled Homepage]',
            tasks => $styled_homepage_tasks,
            Tasks => $styled_homepage_tasks,
        };
        my $storyboards = {
            name => 'Story Boards',
            '[SetupApache]' => $setup_apache,
            '[setupapache]' => $setup_apache,
            '[ModPerl HelloWorld]' => $mod_perl,
            '[modperl helloworld]' => $mod_perl,
            '[Styled Homepage]' => $styled_homepage,
            '[styled homepage]' => $styled_homepage,
            items => [
                $setup_apache,
                $mod_perl,
                $styled_homepage,
            ],
        };
        my $other_info = { 
            text => "Details go here.\n",
            items => [
                'Bullet one',
                'Bullet two',
            ],
        };
        my $page_name = 'data structure correct';
        my $page_data = {
            page => $page_name,
            rester => $rester,
            theme => $theme,
            Theme => $theme,
            People => $people,
            people => $people,
            'Story Boards' => $storyboards,
            'story boards' => $storyboards,
            'Other Information' => $other_info,
            'other information' => $other_info,
            items => [
                $storyboards,
            ],
            headings => [
                'Theme',
                'People',
                'Story Boards',
                '[SetupApache]',
                'Tasks',
                '[ModPerl HelloWorld]',
                'Tasks',
                '[Styled Homepage]',
                'Tasks',
                'Other Information',
            ],
        };

        push @data, {
            page => $page_name,
            page_content => $text,
            expected => $page_data,
        };
    }

    {
        my $text = <<EOT;
^^ Top of the morning

Alpha Bravo

^^^ Ball Tricks

* Mills Mess
* Rubenstein's revenge

^^^ Club Tricks

* Lazy catch

EOT
        my $ball_tricks = [
            q(Mills Mess),
            q(Rubenstein's revenge),
        ];
        my $club_tricks = [
            q(Lazy catch),
        ];
        my $morning_top = {
            name => 'Top of the morning',
            text => "Alpha Bravo\n",
            'Ball Tricks' => $ball_tricks,
            'ball tricks' => $ball_tricks,
            'Club Tricks' => $club_tricks,
            'club tricks' => $club_tricks,
        };
        my $page_name = 'text with items';
        my $page_data = {
            page => $page_name,
            rester => $rester,
            'Top of the morning' => $morning_top,
            'top of the morning' => $morning_top,
            items => [
                $morning_top,
            ],
            headings => [
                'Top of the morning',
                'Ball Tricks',
                'Club Tricks',
            ],
        };
        push @data, {
            page => $page_name,,
            page_content => $text,
            expected => $page_data,
        };
    }

    {
        my $text = <<EOT;
Page with no title:

# one
# two
EOT
        my $page_name = 'page with no title';
        my $page_data = {
            page => $page_name,
            rester => $rester,
            text => "Page with no title:\n",
            items => [
                'one',
                'two',
            ],
        };
        push @data, {
            page => $page_name,
            page_content => $text,
            expected => $page_data,
        };
    }
    return @data;
}
