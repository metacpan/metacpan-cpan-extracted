#!/usr/bin/perl

use strict;
use warnings;

use SVN::Web::Test;
use Test::More;

use POSIX ();

my $can_tidy = eval { require Test::HTML::Tidy; 1 };
my $can_parse_rss = eval { require XML::RSS::Parser; 1 };

my $tidy;
if($can_tidy) {
    $tidy = HTML::Tidy->new();
    $tidy->ignore(text => [ qr/trimming empty <span>/,
			    qr/<table> lacks "summary" attribute/, ]);
}

my $rss;
if($can_parse_rss) {
    $rss = XML::RSS::Parser->new();
}

my $repos = 't/repos';

my $test = SVN::Web::Test->new(repo_path => $repos,
			       repo_dump => 't/test_repo.dump');

my $repo_url = 'file://' . POSIX::getcwd() . '/t/repos';

$test->set_config({ uri_base => 'http://localhost',
		    script   => '/svnweb',
		    config   => { repos => { repos => $repo_url } },
		    });

my $mech = $test->mech();

$mech->get_ok('http://localhost/svnweb/repos/browse/');
$mech->title_is(
    'browse: /repos (Rev: HEAD, via SVN::Web)',
    "'browse' has correct title")
    or diag $mech->content();

$mech->get('http://localhost/svnweb/repos/browse/?rev=1');
$mech->title_is(
    'browse: /repos (Rev: 1, via SVN::Web)',
    "'browse' with rev has correct title")
    or diag $mech->content();

$mech->get('http://localhost/svnweb/repos/revision/?rev=2');
$mech->title_is('revision: /repos (Rev: 2, via SVN::Web)',
    "'revision' has correct title")
    or diag $mech->content();

$mech->get('http://localhost/svnweb/');
$mech->title_is('Repository List (via SVN::Web)', "'list' has correct title")
    or diag $mech->content();

note "Recursively checking all links";

my $test_sub = sub {
    note('skip static files checks in local tests: '.$mech->uri), return
        if $mech->uri->path eq '/' or $mech->uri->path =~ m{/css/};

    is($mech->status, 200, 'Fetched ' . $mech->uri())
        or diag $mech->status;

    # Make sure that there are no '//' in the URI, unless preceeded by
    # a ':'.  This catches template bugs with too many slashes.
    unlike($mech->uri(), qr{(?<!:)//}, 'URI does not contain "//"')
        or diag $mech->uri();

    $mech->content_unlike(qr'An error occured', '  and content was correct')
        or diag $mech->content;

    if($can_tidy 
       and ($mech->uri() !~ m{ (?:
			           / (?: rss | checkout )
                                 | mime=text/plain
			       )}x)) {
	Test::HTML::Tidy::html_tidy_ok($tidy, $mech->content(),
				       '  and is valid HTML ('.$mech->uri.')')
	    or diag($mech->content());
    }

    # Make sure that all local links (like <a href="#anchor"...) has
    # appropriate anchors in code
    my @local_links = $mech->find_all_links(tag=>'a',url_regex=>qr/^\#/);
    foreach (@local_links) {
        my $name = $_->url;
        $name =~ s/^#//;
        $mech->content_like(qr/(?:id|name)=['"]$name(?:['"])/, "  and has element with name='$name' (".$mech->uri.")");
    }

    if($can_parse_rss and ($mech->uri() =~ m{/rss/})) {
        my $feed = $rss->parse_string($mech->content());
        ok(defined $feed, 'RSS parsed successfully')
          or diag $rss->errstr(), diag $mech->content();

        {
            local $TODO = "I'am unsure about this test, in some environments full URL can't be"
                        ." obtained, so may be we can introduce canonical_uri in config?"
                        ." Anyway mark as todo for now";
            # Make sure that each item's <link> element is a full URL
            for my $item ($feed->query('//item')) {
                my $node = $item->query('link');
                like($node->text_content(), qr/^http/, 'RSS link is fully qualified')
                  or diag $node->text_content();
            }
        }
    }
};

$test->walk_site($test_sub);

done_testing;
