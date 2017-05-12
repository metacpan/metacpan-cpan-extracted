#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 39;

use lib './t/lib';

# We need to load the mocking modules first because they fill the
# namespaces and %INC. Otherwise, "use CGI" and "use SVN::*" will cause
# the real modules to be loaded.
use SVN::RaWeb::Light::Mock::CGI;
use SVN::RaWeb::Light::Mock::Svn;
use SVN::RaWeb::Light::Mock::Stdout;

use SVN::RaWeb::Light;

use SVN::RaWeb::Light::Test::LimitOutput;

package main;

{
    @CGI::new_params = ('path_info' => "/trunk/hello/");

    reset_out_buffer();

    my $svn_ra_web = SVN::RaWeb::Light->new('url' => "http://svn-i.shlomifish.org/svn/myrepos");

    # TEST
    ok($svn_ra_web, "Object Initialization Succeeded");
    $svn_ra_web->run();
}

# Checking for multiple adjacent slashes.
{
    @CGI::new_params = ('path_info' => "/hello//you/");

    reset_out_buffer();

    my $svn_ra_web = SVN::RaWeb::Light->new('url' => "http://svn-i.shlomifish.org/svn/myrepos");

    $svn_ra_web->run();

    my $results = get_out_buffer();

    # TEST
    ok(($results =~ /Wrong URL/), "Testing for result on multiple adjacent slashes");
    # TEST
    ok (($results =~ /Multiple Adjacent Slashes/), "Testing for result on multiple adjacent slashes");
}

# Testing redirect from a supposed directory to a file.
{
    local @CGI::new_params = ('path_info' => "/trunk/src/");

    local @SVN::Ra::new_params =
    (
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/src")
            {
                return $SVN::Node::file;
            }
            die "Wrong path queried - $path.";
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    my $exception = $@;

    # TEST
    ok($exception, "Testing that an exception was thrown.");
    # TEST
    is($exception->{'type'}, "redirect", "Excpecting type redirect");
    # TEST
    is($exception->{'redirect_to'}, "../src", "Right redirect URL");
}

# Testing redirect from supposed file to a directory with the same name
{
    local @CGI::new_params = ('path_info' => "/trunk/src.txt");

    local @SVN::Ra::new_params =
    (
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/src.txt")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    my $exception = $@;

    # TEST
    ok($exception, "Testing that an exception was thrown.");
    # TEST
    is($exception->{'type'}, "redirect", "Excpecting type redirect");
    # TEST
    is($exception->{'redirect_to'}, "./src.txt/", "Right redirect URL");
}

{
    local @CGI::new_params = ('path_info' => "/trunk/not-exist");

    local @SVN::Ra::new_params =
    (
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/not-exist")
            {
                return $SVN::Node::none;
            }
            die "Wrong path queried - $path.";
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is($results, ("Content-Type: text/html\n\n" .
        "<html><head><title>Does not exist!</title></head>" .
        "<body><h1>Does not exist!</h1></body></html>"),
        "Checking for correct results for non-existent file"
    );
}


{
    local @CGI::new_params = ('path_info' => "/trunk/invalid");

    local @SVN::Ra::new_params =
    (
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/invalid")
            {
                return $SVN::Node::unknown;
            }
            die "Wrong path queried - $path.";
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is($results, ("Content-Type: text/html\n\n" .
        "<html><head><title>Does not exist!</title></head>" .
        "<body><h1>Does not exist!</h1></body></html>"),
        "Checking for correct results for unknown file"
    );
}

# Test the directory output for a regular (non-root) directory.
{
    local @CGI::new_params = ('path_info' => "/trunk/mydir/");

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "trunk/mydir")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");



    my $results = get_out_buffer();

    # TEST
    is($results, ("Content-Type: text/html\n\n" .
        "<html><head><title>Revision 10900: /trunk/mydir</title></head>\n" .
        "<body>\n" .
        "<h2>Revision 10900: /trunk/mydir</h2>\n" .
        "<ul>\n" .
        "<li><a href=\"../\">..</a></li>\n" .
        "<li><a href=\"hello.pm\">hello.pm</a></li>\n" .
        "<li><a href=\"mydir/\">mydir/</a></li>\n" .
        "</ul>\n".
        "<ul>\n" .
        "<li><a href=\"./?mode=help\">Show Help Screen</a></li>\n" .
        "<li><a href=\"./?panel=1\">Show Control Panel</a></li>\n" .
        "</ul>\n" .
        "</body></html>\n"),
        "Checking for valid output of a dir listing");
}

# Test the directory output for the root directory
{
    local @CGI::new_params = ('path_info' => "/");

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'yowza.txt' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'the-directory' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                    'parser' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is($results, ("Content-Type: text/html\n\n" .
        "<html><head><title>Revision 10900: /</title></head>\n" .
        "<body>\n" .
        "<h2>Revision 10900: /</h2>\n" .
        "<ul>\n" .
        "<li><a href=\"parser\">parser</a></li>\n" .
        "<li><a href=\"the-directory/\">the-directory/</a></li>\n" .
        "<li><a href=\"yowza.txt\">yowza.txt</a></li>\n" .
        "</ul>\n".
        "<ul>\n" .
        "<li><a href=\"./?mode=help\">Show Help Screen</a></li>\n" .
        "<li><a href=\"./?panel=1\">Show Control Panel</a></li>\n" .
        "</ul>\n" .
        "</body></html>\n"),
        "Checking for valid output of a dir listing in root");
}

# Testing for a directory with a specified revision.
{
    local @CGI::new_params =
    (
        'path_info' => "/trunk/subversion/",
        'params' =>
        {
            'rev' => 150,
        },
        'query_string' => "rev=150",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/subversion")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "trunk/subversion")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 150)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'yowza.txt' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'the-directory' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                    'parser' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light::OutputListOnly->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    $svn_ra_web->run();

    my $results = get_out_buffer();

    # TEST
    is($results, (
        "<ul>\n" .
        "<li><a href=\"../?rev=150\">..</a></li>\n" .
        "<li><a href=\"parser?rev=150\">parser</a></li>\n" .
        "<li><a href=\"the-directory/?rev=150\">the-directory/</a></li>\n" .
        "<li><a href=\"yowza.txt?rev=150\">yowza.txt</a></li>\n" .
        "</ul>\n"),
        "Checking for valid output of a dir listing in root");
}

# Checking the retrieving of a file.
{
    local @CGI::new_params = ('path_info' => "/trunk/mydir/myfile.txt");

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir/myfile.txt")
            {
                return $SVN::Node::file;
            }
            die "Wrong path queried - $path.";
        },
        'get_file' => sub {
            my ($self, $path, $rev_num, $out_fh) = @_;
            if ($path ne "trunk/mydir/myfile.txt")
            {
                die "Wrong path - $path";
            }
            if ($rev_num != 10900)
            {
                die "Wrong revision - $rev_num";
            }
            print {$out_fh} "<html><body>\nTesting One tWO t|-||/33 - Subversion ownz.\n</body></html>";
            return (10900, { 'svn:mime-type' => "text/html", });
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    $svn_ra_web->run();

    my $results = get_out_buffer();

    # TEST
    is($results, ("Content-Type: text/html\n\n" .
        "<html><body>\nTesting One tWO t|-||/33 - " .
        "Subversion ownz.\n</body></html>"),
        "Testing for get_file()"
    );
}


# Checking the retrieving of a file without a mime type.
{
    local @CGI::new_params = ('path_info' => "/trunk/mydir/myfile.txt");

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir/myfile.txt")
            {
                return $SVN::Node::file;
            }
            die "Wrong path queried - $path.";
        },
        'get_file' => sub {
            my ($self, $path, $rev_num, $out_fh) = @_;
            if ($path ne "trunk/mydir/myfile.txt")
            {
                die "Wrong path - $path";
            }
            if ($rev_num != 10900)
            {
                die "Wrong revision - $rev_num";
            }
            print {$out_fh} "Yo, yo, yo!\nTime to get busy...\n";
            return (10900, {});
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    $svn_ra_web->run();

    my $results = get_out_buffer();

    # TEST
    is($results, ("Content-Type: text/plain\n\n" .
        "Yo, yo, yo!\nTime to get busy...\n"),
        "Checking for retrieving a file with no mime type."
    );
}

# Check that if the script is hosted at http://myhost.foo/serve.pl, and the
# URL accessed is "http://myhost.foo/serve.pl" then it should redirect to
# http://myhost.foo/serve.pl/.
{
    local @CGI::new_params =
    (
        'path_info' => "",
        'script_name' => "/cgi-bin/shlomi/serve-67jyumber200.pl",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir/myfile.txt")
            {
                return $SVN::Node::file;
            }
            die "Wrong path queried - $path.";
        },
        'get_file' => sub {
            my ($self, $path, $rev_num, $out_fh) = @_;
            if ($path ne "trunk/mydir/myfile.txt")
            {
                die "Wrong path - $path";
            }
            if ($rev_num != 10900)
            {
                die "Wrong revision - $rev_num";
            }
            print {$out_fh} "Yo, yo, yo!\nTime to get busy...\n";
            return (10900, {});
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/"
        );

    eval {
    $svn_ra_web->run();
    };

    my $exception = $@;

    # TEST
    ok($exception, "Checking for exception");
    # TEST
    is($exception->{'type'}, "redirect", "Excpecting type redirect");
    # TEST
    is($exception->{'redirect_to'}, "./serve-67jyumber200.pl/",
        "Right redirect URL");
}

# Check for url_translations of a regular (non-root) directory.
{
    local @CGI::new_params = ('path_info' => "/trunk/mydir/");

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "trunk/mydir")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light::OutputTransAndList->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
            'url_translations' =>
            [
                {
                    'label' => "Read-Only",
                    'url' => "svn://svn.myhost.mytld/hello/there/",
                },
                {
                    'label' => "Write",
                    'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
                },
            ],
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is_deeply([split(/\n/, $results)], [(split /\n/, <<"EOF")]
<table border=\"1\">
<tr><td><a href=\"svn://svn.myhost.mytld/hello/there/trunk/mydir/\">Read-Only</a></td></tr>
<tr><td><a href=\"svn+ssh://svnwrite.myhost.mytld/root/myroot/trunk/mydir/\">Write</a></td></tr>
</table>
<ul>
<li><a href=\"../\">..</a> [<a href="svn://svn.myhost.mytld/hello/there/trunk/">Read-Only</a>] [<a href="svn+ssh://svnwrite.myhost.mytld/root/myroot/trunk/">Write</a>]</li>
<li><a href=\"hello.pm\">hello.pm</a> [<a href="svn://svn.myhost.mytld/hello/there/trunk/mydir/hello.pm">Read-Only</a>] [<a href="svn+ssh://svnwrite.myhost.mytld/root/myroot/trunk/mydir/hello.pm">Write</a>]</li>
<li><a href=\"mydir/\">mydir/</a> [<a href="svn://svn.myhost.mytld/hello/there/trunk/mydir/mydir/">Read-Only</a>] [<a href="svn+ssh://svnwrite.myhost.mytld/root/myroot/trunk/mydir/mydir/">Write</a>]</li>
</ul>
EOF
    , "Check for url_translations of a regular (non-root) directory.");
}

# Check for url_translations of a regular (non-root) directory.
# With trans_no_list=1.
{
    local @CGI::new_params =
    (
        'path_info' => "/trunk/mydir/",
        'params' =>
        {
            'trans_no_list' => 1,
        },
        'query_string' => "trans_no_list=1",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "trunk/mydir")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light::OutputTransAndList->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
            'url_translations' =>
            [
                {
                    'label' => "Read-Only",
                    'url' => "svn://svn.myhost.mytld/hello/there/",
                },
                {
                    'label' => "Write",
                    'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
                },
            ],
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is_deeply([split(/\n/, $results)], [(split /\n/, <<"EOF")]
<table border=\"1\">
<tr><td><a href=\"svn://svn.myhost.mytld/hello/there/trunk/mydir/\">Read-Only</a></td></tr>
<tr><td><a href=\"svn+ssh://svnwrite.myhost.mytld/root/myroot/trunk/mydir/\">Write</a></td></tr>
</table>
<ul>
<li><a href=\"../?trans_no_list=1\">..</a></li>
<li><a href=\"hello.pm?trans_no_list=1\">hello.pm</a></li>
<li><a href=\"mydir/?trans_no_list=1\">mydir/</a></li>
</ul>
EOF
    , "Checking for trans_no_list=1");
}

# Check for url_translations of a regular (non-root) directory.
# With trans_hide_all=1.
{
    local @CGI::new_params =
    (
        'path_info' => "/trunk/mydir/",
        'params' =>
        {
            'trans_hide_all' => 1,
            'trans_user' => "MyUrl,http://y.y/",
        },
        'query_string' => "trans_hide_all=1&trans_user=MyUrl,http://y.y/",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "trunk/mydir")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light::OutputTransAndList->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
            'url_translations' =>
            [
                {
                    'label' => "Read-Only",
                    'url' => "svn://svn.myhost.mytld/hello/there/",
                },
                {
                    'label' => "Write",
                    'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
                },
            ],
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is_deeply([split(/\n/, $results)], [(split /\n/, <<"EOF")]
<table border="1">
<tr><td><a href="http://y.y/trunk/mydir/">MyUrl</a></td></tr>
</table>
<ul>
<li><a href=\"../?trans_hide_all=1&amp;trans_user=MyUrl,http://y.y/\">..</a> [<a href="http://y.y/trunk/">MyUrl</a>]</li>
<li><a href=\"hello.pm?trans_hide_all=1&amp;trans_user=MyUrl,http://y.y/\">hello.pm</a> [<a href="http://y.y/trunk/mydir/hello.pm">MyUrl</a>]</li>
<li><a href=\"mydir/?trans_hide_all=1&amp;trans_user=MyUrl,http://y.y/\">mydir/</a> [<a href="http://y.y/trunk/mydir/mydir/">MyUrl</a>]</li>
</ul>
EOF
    , "Checking for trans_no_list=1");
}

# Check for url_translations of a regular (non-root) directory.
# With trans_hide_all=1 and trans_no_list.
{
    local @CGI::new_params =
    (
        'path_info' => "/trunk/mydir/",
        'params' =>
        {
            'trans_hide_all' => 1,
            'trans_user' => "MyUrl,http://y.y/",
            'trans_no_list' => 1,
        },
        'query_string' => "trans_hide_all=1&trans_user=MyUrl,http://y.y/&trans_no_list=1",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "trunk/mydir")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "trunk/mydir")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light::OutputTransAndList->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
            'url_translations' =>
            [
                {
                    'label' => "Read-Only",
                    'url' => "svn://svn.myhost.mytld/hello/there/",
                },
                {
                    'label' => "Write",
                    'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
                },
            ],
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is_deeply([split(/\n/, $results)], [(split /\n/, <<"EOF")]
<table border="1">
<tr><td><a href="http://y.y/trunk/mydir/">MyUrl</a></td></tr>
</table>
<ul>
<li><a href=\"../?trans_hide_all=1&amp;trans_user=MyUrl,http://y.y/&amp;trans_no_list=1\">..</a></li>
<li><a href=\"hello.pm?trans_hide_all=1&amp;trans_user=MyUrl,http://y.y/&amp;trans_no_list=1\">hello.pm</a></li>
<li><a href=\"mydir/?trans_hide_all=1&amp;trans_user=MyUrl,http://y.y/&amp;trans_no_list=1\">mydir/</a></li>
</ul>
EOF
    , "Checking for trans_no_list=1");
}

# Check for url_translations of a root directory
{
    local @CGI::new_params = ('path_info' => "/");

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            return 10900;
        },
        'check_path' => sub {
            my ($self, $path, $rev_num) = @_;
            if ($path eq "")
            {
                return $SVN::Node::dir;
            }
            die "Wrong path queried - $path.";
        },
        'get_dir' => sub {
            my $self = shift;
            my $path = shift;
            my $rev_num = shift;

            if ($path ne "")
            {
                die "Wrong Path - $path";
            }

            if ($rev_num != 10900)
            {
                die "Wrong rev_num - $rev_num";
            }

            return
            (
                {
                    'hello.pm' =>
                    {
                        'kind' => $SVN::Node::file,
                    },
                    'mydir' =>
                    {
                        'kind' => $SVN::Node::dir,
                    },
                },
                $rev_num
            );
        },
    );
    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light::OutputTransAndList->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
            'url_translations' =>
            [
                {
                    'label' => "Read-Only",
                    'url' => "svn://svn.myhost.mytld/hello/there/",
                },
                {
                    'label' => "Write",
                    'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
                },
            ],
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is_deeply([split(/\n/, $results)], [(split /\n/, <<"EOF")]
<table border=\"1\">
<tr><td><a href=\"svn://svn.myhost.mytld/hello/there/\">Read-Only</a></td></tr>
<tr><td><a href=\"svn+ssh://svnwrite.myhost.mytld/root/myroot/\">Write</a></td></tr>
</table>
<ul>
<li><a href=\"hello.pm\">hello.pm</a> [<a href="svn://svn.myhost.mytld/hello/there/hello.pm">Read-Only</a>] [<a href="svn+ssh://svnwrite.myhost.mytld/root/myroot/hello.pm">Write</a>]</li>
<li><a href=\"mydir/\">mydir/</a> [<a href="svn://svn.myhost.mytld/hello/there/mydir/">Read-Only</a>] [<a href="svn+ssh://svnwrite.myhost.mytld/root/myroot/mydir/">Write</a>]</li>
</ul>
EOF
    , "Check for url_translations of a regular (non-root) directory.");
}


# Check for the help being displayed properly.
{
    local @CGI::new_params =
    (
        'path_info' => "/",
        'params' =>
        {
            'mode' => "help",
        },
        'query_string' => "mode=help",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            die "Called get_latest_revnum and shouldn't";
        },
        'check_path' => sub {
            die "Called check_path and shouldn't";
        },
        'get_dir' => sub {
            die "Called get_dir and shouldn't";
        },
    );

    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    # Make sure that we print the header.
    like($results, qr{^Content-Type: text/html\n\n},
        "Check for a valid header");
    # TEST
    like($results, qr{<title>SVN::RaWeb::Light Help Screen</title>},
        "Check for a valid help screen - title");
    # TEST
    like($results, qr{<h1>SVN::RaWeb::Light Help Screen</h1>},
        "Check for a valid help screen - h1");
}

# Check for the panel parameter displaying an error notice - temporarily
# until it's implemented.
{
    local @CGI::new_params =
    (
        'path_info' => "/",
        'params' =>
        {
            'panel' => "1",
        },
        'query_string' => "panel=1",
    );

    local @SVN::Ra::new_params =
    (
        'get_latest_revnum' => sub {
            die "Called get_latest_revnum and shouldn't";
        },
        'check_path' => sub {
            die "Called check_path and shouldn't";
        },
        'get_dir' => sub {
            die "Called get_dir and shouldn't";
        },
    );

    reset_out_buffer();

    my $svn_ra_web =
        SVN::RaWeb::Light->new(
            'url' => "http://svn-i.shlomifish.org/svn/myrepos/",
        );

    eval {
    $svn_ra_web->run();
    };

    # TEST
    ok(!$@, "Testing that no exception was thrown.");

    my $results = get_out_buffer();

    # TEST
    is ($results, <<"EOF",
Content-Type: text/html

<html><body><h1>Not Implemented Yet</h1>
<p>Sorry but the control panel is not implemented yet.</p>
</body>
</html>
EOF
        "Temporary check for control panel not-impl yet msg.");
}

1;

