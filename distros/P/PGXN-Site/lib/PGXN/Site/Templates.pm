package PGXN::Site::Templates;

use 5.10.0;
use utf8;
use parent 'Template::Declare';
use PGXN::Site;
use PGXN::Site::Locale;
use Template::Declare::Tags;
use Software::License::PostgreSQL;
use Software::License::BSD;
use Software::License::MIT;
use List::Util qw(first);
use File::Basename qw(basename);
use SemVer;
use Gravatar::URL;
#use namespace::autoclean; # Do not use; breaks sort {}
our $VERSION = v0.10.3;

my $l = PGXN::Site::Locale->get_handle('en');
sub T { $l->maketext(@_) }

BEGIN { create_wrapper wrapper => sub {
    my ($code, $req, $args) = @_;
    $l = PGXN::Site::Locale->accept($req->env->{HTTP_ACCEPT_LANGUAGE});
    outs_raw '<!DOCTYPE html>';
    html {
        attr {
            xmlns      => 'http://www.w3.org/1999/xhtml',
            'xml:lang' => 'en',
            lang       => 'en',
        };
        outs_raw( "\n", join "\n",
            '<!--',
            '____________________________________________________________',
            '|                                                            |',
            '|    DESIGN + Pat Heard { http://fullahead.org }             |',
            '|      DATE + 2006.03.19                                     |',
            '| COPYRIGHT + Free use if this notice is left in place       |',
            '|____________________________________________________________|',
            '-->'
        );

        head {
            title { $args->{title} };
            meta {
                name is 'keywords';
                content is 'PostgreSQL, extensions, PGXN, PostgreSQL Extension Network';
            };
            meta {
                name is 'description';
                content is 'Search all indexed extensions, distributions, '
                         . 'users, and tags on the PostgreSQL Extension Network.';
            };
            for my $spec (
                [ html   => 'screen, projection, tv' ],
                [ layout => 'screen, projection, tv' ],
                [ print  => 'print'                  ],
            ) {
                link {
                    rel   is 'stylesheet';
                    type  is 'text/css';
                    href  is "/ui/css/$spec->[0].css?" . PGXN::Site->version_string;
                    media is $spec->[1];
                };
            }
        }; # /head

        body {
            # HEADER: Holds title, subtitle and header images -->
            div {
                id is 'all';
                div {
                    id is 'header';
                    div {
                        id is 'title';
                        h1 { 'PGXN' };
                        h2 { T 'PostgreSQL Extension Network' };
                    };
                    a {
                        href is '/';
                        rel is 'home';
                        img {
                            src   is '/ui/img/gear.png';
                            alt   is T 'PGXN Gear';
                            class is 'gear';
                        };
                        img {
                            src   is '/ui/img/pgxn.png';
                            alt   is T 'PostgreSQL Extension Network';
                            class is 'right';
                        };
                    };
                }; # /div#header
                # CONTENT: Holds all site content except for the footer. This
                # is what causes the footer to stick to the bottom
                div {
                    id is 'content';
                    # MAIN MENU: Top horizontal menu of the site. Use
                    # class="here" to turn the current page tab on.
                    div {
                        id is 'mainMenu';
                        if (my $crumb = $args->{crumb}) {
                            ul {
                                id is 'crumb';
                                class is 'floatLeft';
                                $crumb->();
                            }
                        }
                        ul {
                            class is 'floatRight';
                            my $path = $req->uri->path;
                            for my $spec (
                                [ '/recent/', 'Recent Releases',            'Recent'  ],
                                [ '/users/',  'PGXN Users',                 'Users'   ],
                                [ '/about/',  'About PGXN',                 'About'   ],
                                [ '/faq/',    'Frequently Asked Questions', 'FAQ'     ],
                            ) {
                                li {
                                    class is 'here' if $path eq $spec->[0];
                                    a {
                                        href is $spec->[0];
                                        title is T $spec->[1];
                                        T $spec->[2];
                                    };
                                };
                            }
                        };
                    }; # /div#mainMenu

                    # Content goes here!
                    $code->();

                }; # /div#content
            }; # /div#all

            # FOOTER: Site footer for links, copyright, etc.
            div {
                id is 'footer';
                div {
                    id is 'width';
                    span {
                        class is 'floatLeft';
                        outs +PGXN::Site->version_string;
                        span { class is 'grey'; '|' };
                        outs 'code';
                        a {
                            href is 'http://www.justatheory.com/';
                            title is T 'Go to [_1]', 'Just a Theory';
                            'theory';
                        };
                        span { class is 'grey'; '|' };
                        outs ' design';
                        a {
                            href is 'http://fullahead.org/';
                            title is T 'Go to [_1]', 'Fullahead';
                            'Fullahead';
                        };
                        span { class is 'grey'; '|' };
                        outs ' logo';
                        a {
                            href is 'http://www.strongrrl.com/';
                            title is T 'Go to [_1]', 'Strongrrl';
                            'Strongrrl';
                        };
                    }; # /span.floatLeft
                    span {
                        class is 'floatRight';
                        a {
                            href is 'http://blog.pgxn.org/';
                            title is T 'PGXN Blog';
                            T 'Blog';
                        };
                        span { class is 'grey'; '|' };
                        a {
                            href is 'http://twitter.com/pgxn/';
                            title is T 'Follow PGXN on Twitter';
                            T 'Twitter';
                        };
                        span { class is 'grey'; '|' };
                        a {
                            href is 'http://manager.pgxn.org/';
                            title is T 'Release it on PGXN';
                            T 'Release It';
                        };
                        span { class is 'grey'; '|' };
                        a {
                            href is '/mirroring/';
                            title is T 'Mirroring';
                            T 'Mirroring';
                        };
                        span { class is 'grey'; '|' };
                        a {
                            href is '/donors/';
                            title is T 'Donors';
                            T 'Donors';
                        };
                        span { class is 'grey'; '|' };
                        a {
                            href is '/art/';
                            title is T 'Identity';
                            T 'Identity';
                        };
                        span { class is 'grey'; '|' };
                        a {
                            href is '/feedback/';
                            title is T 'Feedback';
                            T 'Feedback';
                        };
                    }; # /span.floatRight
                }; # /div#width
            }; # /div#footer
        }; # /body
    }; # /html
}; }


template home => sub {
    my ($self, $req, $args) = @_;
    wrapper {
        div {
            id is 'homepage';
            div {
                class is 'hsearch floatLeft';
                show search_form => {
                    id       => 'homesearch',
                    in        => 'doc',
                    autofocus => 1,
                };

                outs_raw $args->{cloud}->html;
            }; # /div.hsearch floatLeft

            # 25 percent width column, aligned to the right.
            div {
                class is 'hside floatLeft gradient';
                p { T 'pgxn_summary_paragraph' };
                h3 { T 'Recent Releases' };
                my $dists = $args->{dists};
                if ($dists && @{ $dists }) {
                    dl {
                        id is 'recent';
                        for my $dist (@{ $dists }) {
                            dt { a {
                                my @vals = map { $dist->{$_} } qw(dist version);
                                href is '/dist/' . lc join('/', @vals) . '/';
                                join ' ', @vals
                            } };
                            dd { $dist->{abstract} };
                        };
                    };
                    h6 {
                        class is 'floatRight';
                        a {
                            href is '/recent/';
                            title is T 'See a longer list of recent releases.';
                            T 'More Releases';
                        }
                    };
                } else {
                    p { T 'No Releases Yet' }
                }
            }; # /div.hside floatLeft gradient

        }; # /div#homepage
    } $req, { title => T 'hometitle' };
};

sub _title_with($) {
    $_[0] . ' / ' . T 'PostgreSQL Extension Network';
}

template distribution => sub {
    my ($self, $req, $args) = @_;
    my $dist = $args->{dist};
    wrapper {
        div {
            id is 'page';
            class is 'dist';
            div {
                class is 'gradient meta';
                div {
                    class is 'controls';
                    span {
                        class is 'download';
                        a {
                            class is 'url';
                            href is URI->new($args->{api_url} . $dist->download_path);
                            title is T 'Download [_1] [_2]', $dist->name, $dist->version;
                            img {
                                src is '/ui/img/download.png';
                                alt is T 'Download';
                            };
                        };
                    }; # /span.download
                    span {
                        class is 'browse';
                        a {
                            class is 'url';
                            href is URI->new($args->{api_url} . $dist->source_path);
                            title is T 'Browse [_1] [_2]', $dist->name, $dist->version;
                            img {
                            src is '/ui/img/package.png';
                            alt is T 'Browse';
                        };
                        };
                    }; # /span.download
                }; # /div.controls
                h1 { $args->{dist_name} };
                dl {
                    dt { T 'This Release' };
                    dd {
                        span { class is 'fn';      $dist->name };
                        span { class is 'version'; $dist->version };
                    };
                    dt { T 'Date' };
                    dd {
                        my $datetime = $dist->date;
                        (my $date = $datetime) =~ s{T.+}{};
                        # Looking forward to HTML 5 in Template::Declare.
                        outs_raw qq{<time class="bday" datetime="$datetime">$date</time>};
                    };
                    dt { T 'Status' };
                    dd { T $dist->release_status };
                    my $rel = $dist->releases;
                    my @rels = @{ $rel->{stable} || [] };
                    if (my @others = (@{ $rel->{testing}  || [] }, @{ $rel->{unstable} || [] })) {
                        @rels =
                            map  { $_->[0] }
                            sort { $b->[1] <=> $a->[1] }
                            map  { [ $_ => SemVer->declare($_->{version}) ] } @rels, @others;
                    }
                    if (@rels > 1) {
                        # Show latest version for other statuses.
                        for my $status (qw(Stable Testing Unstable)) {
                            my $stat_version = $dist->version_for(lc $status) or next;
                            if ($dist->version ne $stat_version) {
                                dt { T "Latest $status" };
                                dd {
                                    my $datetime = $dist->date_for(lc $status);
                                    (my $date = $datetime) =~ s{T.+}{};
                                    a {
                                        href is '/dist/' . $dist->name . lc "/$stat_version/";
                                        outs $dist->name . " $stat_version — ";
                                        outs_raw qq{<time datetime="$datetime">$date</time>};
                                    }
                                };
                            }
                        }
                        # Create a select list of all other versions.
                        dt { class is 'other'; T 'Other Releases' };
                        dd {
                            select {
                                onchange is 'window.location.href = this.options[this.selectedIndex].value';
                                my $version = $dist->version;
                                for my $rel (@rels) {
                                    # Include release status in the option name?
                                    option {
                                        value is '/dist/' . lc $dist->name . lc "/$rel->{version}/";
                                        selected is 'selected' if $rel->{version} eq $version;
                                        (my $date = $rel->{date}) =~ s{T.+}{};
                                        $dist->name . " $rel->{version} — $date";
                                    };
                                }
                            };
                        };
                    }
                    dt { T 'Abstract' };
                    dd { class is 'abstract'; $dist->abstract };
                    if (my $descr = $dist->description) {
                        dt { T 'Description' };
                        dd { class is 'description'; $descr };
                    }
                    dt { T 'Released By' };
                    dd {
                        span { class is 'vcard'; a {
                            class is 'url fn';
                            href is '/user/' . lc $dist->user;
                            $dist->user;
                        }};
                    };
                    dt { T 'License' };
                    dd {
                        if (ref $dist->license eq 'HASH') {
                            my $licenses = $dist->license;
                            for my $license (sort keys %{ $licenses }) {
                                a {
                                    rel is 'license';
                                    href is $licenses->{$license};
                                    $license;
                                };
                            }
                        } else {
                            for my $l (ref $dist->license ? @{ $dist->license } : ($dist->license)) {
                                if (my $license = _license($l)) {
                                    a {
                                        rel is 'license';
                                        href is $license->url;
                                        $license->name;
                                    };
                                } else {
                                    my %other_strings = (
                                        map { $_ => 1 } qw(open_source restricted unrestricted)
                                    );
                                    outs $other_strings{$l} ? $l : 'unknown';
                                }
                            }
                            for my $license (grep {
                                defined
                            } map {
                                _license($_)
                            } ref $dist->license ? @{ $dist->license } : ($dist->license)) {
                            }
                        }
                    };
                    my $res = $dist->resources;
                    if (%{ $res }) {
                        dt { T 'Resources' };
                        my @res;
                        if (my $url = $res->{homepage}) {
                            push @res => [ 'url', $url, T 'www' ];
                        }
                        if (my $repo = $res->{repository}) {
                            if (my $url = $repo->{url}) {
                                push @res => [ 'url', $url, $repo->{type} ];
                            }
                            if (my $url = $repo->{web}) {
                                # XXX Think of a better name than "repo"?
                                push @res => [ 'url', $url, T 'repo' ];
                            }
                        }
                        if (my $bug = $res->{bugtracker}) {
                            if (my $url = $bug->{web}) {
                                push @res => [ 'url', $url, T 'bugs' ]
                            }

                            if (my $email = $bug->{mailto}) {
                                push @res => [ 'email', "mailto:$email", $email ]
                            }
                        }
                        dd {
                            class is 'resources';
                            ul {
                                my $last = pop @res;
                                for my $spec (@res) {
                                    li {
                                        a {
                                            class is $spec->[0];
                                            href is $spec->[1];
                                            $spec->[2];
                                        };
                                    };
                                }
                                li {
                                    class is 'last';
                                    a {
                                        class is $last->[0];
                                        href is $last->[1];
                                        $last->[2];
                                    };
                                };
                            };
                        };
                    }
                    if (my @files = $dist->special_files) {
                        dt { T 'Special Files' };
                        dd {
                            class is 'files';
                            ul {
                                my $uri = $args->{api_url} . $dist->source_path;
                                for my $file (@files) {
                                    li {
                                        class is 'last' if $file eq $files[-1];
                                        a {
                                            href is URI->new("$uri$file");
                                            $file;
                                        };
                                    };
                                }
                            }
                        };
                    }
                    if (my @tags = $dist->tags) {
                        dt { T 'Tags' };
                        dd {
                            class is 'tags';
                            ul {
                                my $last = pop @tags;
                                for my $tag (@tags) {
                                    li { a {
                                        href is URI->new(lc "/tag/$tag/");
                                        $tag;
                                    } };
                                }
                                li {
                                    class is 'last';
                                    a {
                                        href is URI->new(lc "/tag/$last/");
                                        $last;
                                    };
                                };
                            };
                        };
                    }
                }; # /dl
            }; # /div.gradient meta

            my $docs = $dist->docs;
            my $sep = $req->uri =~ m{/$} ? '' : '/';
            div {
                class is 'gradient exts';
                h3 { T 'Extensions' };
                dl {
                    my $provides = $dist->provides;
                    for my $ext (sort { $a cmp $b } keys %{ $provides }) {
                        my $info = $provides->{$ext};
                        my $path = $info->{docpath};
                        dt {
                            if ($path) {
                                delete $docs->{$path};
                                a {
                                    href is $req->uri->path . "$sep$path.html";
                                    span { class is 'fn';       $ext             };
                                    span { class is 'version';  $info->{version} };
                                };
                            } else {
                                span { class is 'fn';       $ext             };
                                span { class is 'version';  $info->{version} };
                            }
                        };
                        dd { class is 'abstract'; $info->{abstract} };
                    }
                } # /dl
            }; # /div.gradient exts

            my $has_readme = delete $docs->{README};

            if (%{ $docs }) {
                div {
                    class is 'gradient docs';
                    h3 { T 'Documentation' };
                    dl {
                        while (my ($path, $info) = each %{ $docs }) {
                            dt {
                                class is 'doc';
                                a {
                                    href is $req->uri->path . "$sep$path.html";
                                    span {
                                        class is 'fn';
                                        if ($info->{abstract}) {
                                            outs $info->{title}
                                        } else {
                                            outs basename $path;
                                        }
                                    };
                                };
                            };
                            dd { class is 'abstract'; $info->{abstract} || $info->{title} };
                        }
                    };
                };
            }

            if ($has_readme) {
                my $body = $dist->body_for_html_doc('README');
                utf8::decode $body;
                div {
                    class is 'gradient exts readme';
                    h3 { T 'README' };
                    outs_raw $body;
                };
            }
        }; # /div#page
    } $req, {
        title => _title_with $args->{dist_name} . ': ' . $dist->abstract,
        crumb => sub {
            li { a {
                href is '/user/' . lc $dist->user;
                title is $dist->user;
                $dist->user;
            } };
            li {
                class is 'sub here';
                a {
                    href is $req->uri->path;
                    title is $args->{dist_name};
                    $args->{dist_name};
                }
            };
        },
    };
};


template document => sub {
    my ($self, $req, $args) = @_;
    my $dist = $args->{dist};
    my $info = $dist->docs->{$args->{docpath}};
    my $title = $info->{abstract} ? $info->{title} : basename $args->{docpath};

    wrapper {
        div {
            id is 'page';
            class is 'doc';
            outs_raw $args->{body};
        }; # /div#page
    } $req, {
        title => _title_with $title . ($info->{abstract} ? ": $info->{abstract}" : ''),
        crumb => sub {
            li { a {
                href is '/user/' . lc $dist->user;
                title is $dist->user;
                $dist->user;
            } };
            li {
                class is 'sub';
                a {
                    href is $args->{dist_uri};
                    title is $args->{dist_name};
                    $args->{dist_name};
                }
            };
            li {
                class is 'sub here';
                a {
                    href is $req->uri->path;
                    title is $title;
                    $title;
                }
            };
        },
    };
};

template spec => sub {
    my ($self, $req, $args) = @_;
    my $title = T 'PGXN Meta Spec';

    wrapper {
        div {
            id is 'page';
            class is 'doc';
            outs_raw $args->{body};
        }; # /div#page
    } $req, {
        title => _title_with $title,
    };
};

template user => sub {
    my ($self, $req, $args) = @_;
    my $user = $args->{user};
    my $api  = $args->{api};

    wrapper {
        div {
            id is 'page';
            class is 'dist';
            div {
                class is 'gradient meta vcard';
                a {
                    class is 'avatar';
                    href is $user->uri || $req->uri->path;
                    img {
                        src is gravatar_url(
                            rating  => 'pg',
                            email   => $user->email,
                            size    => 80,
                            default => $req->base . 'ui/img/shirt.png',
                        );
                    };
                };
                h1 { class is 'fn'; $user->name };
                dl {
                    dt { T 'Nickname' };
                    dd {a {
                        class is 'nickname';
                        href is '/user/' . lc $user->nickname;
                        $user->nickname;
                    } };
                    dt { T 'Email' };
                    dd {
                        class is 'email';
                        outs_raw _link_for_email($user->email);
                    };
                    if (my $uri = $user->uri) {
                        dt { T 'URL' };
                        dd {
                            class is 'url';
                            a { href is $uri; $uri; };
                        };
                    }
                    if (my $t = $user->twitter) {
                        dt { T 'Twitter' };
                        dd {
                            class is 'twitter';
                            a { href is "http://twitter.com/$t"; $t };
                        };
                    }
                };
            }; # /div.gradient meta vcard

            show release_table => $req, $user->releases, $args;
        }; # /div#page
    } $req, {
        title => _title_with $user->name . ' (' . $user->nickname . ')',
    };
};

template tag => sub {
    my ($self, $req, $args) = @_;
    my $tag = $args->{tag};
    my $api = $args->{api};
    my $title = T 'Tag: [_1]', $tag->name;

    wrapper {
        div {
            id is 'page';
            class is 'dist';
            h1 { $title };
            show release_table => $req, $tag->releases, $args;
        }; # /div#page
    } $req, {
        title => _title_with $title,
    };
};

template recent => sub {
    my ($self, $req, $args) = @_;
    my $dists = $args->{dists};
    my $title = T 'Recent Releases';

    wrapper {
        div {
            id is 'page';
            div {
                id is 'results';
                class is 'gradient';
                h1 { $title };
                if ($dists && @{ $dists }) {
                    show 'results/recent' => $dists;
                } else {
                    h3 { T 'No Releases Yet' }
                }
            }; # /div.gradient
        }; # div#page
    } $req, {
        title => _title_with $title,
    }
};

template users => sub {
    my ($self, $req, $args) = @_;
    my $api   = $args->{api};
    my $users = $args->{users};
    my $title = T 'Users';
    my $char  = $args->{char} || '';

    wrapper {
        div {
            class is 'width10 floatLeft leftColumn';
            ul {
                my $uri = $req->uri->path;
                for my $c ('a'..'z') {
                    li {
                        $c eq $char ? $c : a {
                            href is "$uri?c=$c";
                            $c;
                        };
                    };
                }
            };
        };
        div {
            class is 'width90 floatRight gradient';
            h1 { $title };
            if ($users) {
                id is 'results';
                if (@{ $users }) {
                    $args->{params} = [ c => $char ];
                    show 'results/users' => $users;
                } else {
                    p { T 'No user nicknames found starting with "[_1]"', $char };
                }
            } else {
                h3 { T '<- Select a letter' };
            }
        };
    } $req, {
        title => _title_with $title,
    };
};

template search => sub {
    my ($self, $req, $args) = @_;
    my $api  = $args->{api};
    my $res = $args->{results};

    wrapper {
        div {
            id is 'page';
            div {
                id is 'results';
                class is 'gradient';
                if ($res->{hits} && @{ $res->{hits} }) {
                    $args->{params} = [
                        in => $args->{in},
                        q  => $res->{query},
                        l  => $res->{limit},
                    ];
                    show results => $req, $args;
                } else {
                    h3 { T 'Search matched no documents.' }
                }
            }; # /div.gradient
        }; # div#page
    } $req, {
        title => $args->{results}{query} . ' / ' . T('PGXN Search'),
        crumb => sub {
            li {
                class is 'notmenu';
                show search_form => {
                    in => $args->{in},
                    id => 'resultsearch',
                    %{ $res },
                };
            }
        },
    };
};

template results => sub {
    my ($self, $req, $args) = @_;
    my $res = $args->{results};
    my $hits = $res->{hits};
    h3 {
        T '[_1]-[_2] of [_3] found',
            $res->{offset} + 1,
            $res->{offset} + @$hits,
            $res->{count};
    };
    show "results/$args->{in}" => $hits;
    if (my $c = $res->{count}) {
        my $uri = URI->new($req->uri->path);
        my @params = @{ $args->{params} };
        div {
            class is 'searchnav';
            if ($res->{offset}) {
                p {
                    class is 'floatLeft';
                    a {
                        $uri->query_form(
                            @params,
                            o => $res->{offset} - $res->{limit}
                        );
                        href is $uri;
                        title is T 'Previous results';
                        T '← Prev';
                    };
                };
            }
            if ($c > $res->{offset} + $res->{limit}) {
                p {
                    class is 'floatRight';
                    style is 'clear:right';
                    a {
                        $uri->query_form(
                            @params,
                            o => $res->{offset} + $res->{limit}
                        );
                        href is $uri;
                        title is T 'Next results';
                        T 'Next →';
                    };
                };
            }
        };
    }
};

template 'results/extensions' => sub {
    _detailed_results(extension => $_[1]);
};

template 'results/docs' => sub {
    _detailed_results(title => $_[1]);
};

# template 'results/detailed' => sub {
sub _detailed_results {
    my $label = shift;
    for my $hit (@{ +shift }) {
        div {
            class is 'res';
            h2 {
                if ($hit->{docpath}) {
                    a {
                        href is '/dist/' . lc $hit->{dist} . "/$hit->{docpath}.html";
                        $hit->{$label}
                    };
                } else {
                    $hit->{$label}
                }
            };
            p { outs_raw $hit->{excerpt} };
            ul {
                li {
                    class is 'dist';
                    a {
                        href is lc "/dist/$hit->{dist}/";
                        title is T 'In the [_1] distribution', $hit->{dist};
                        "$hit->{dist} $hit->{version}";
                    };
                };
                li {
                    class is 'date';
                    (my $date = $hit->{date}) =~ s{T.+}{};
                    # Looking forward to HTML 5 in Template::Declare.
                    outs_raw qq{<time class="bday" datetime="$hit->{date}">$date</time>};
                };
                li {
                    class is 'user';
                    a {
                        href is lc "/user/$hit->{user}/";
                        title is T 'Released by [_1]', $hit->{user_name};
                        $hit->{user_name};
                    };
                };
            };
        };
    }
};

template 'results/dists' => sub {
    _dist_results(['dist'], $_[1]);
};

template 'results/recent' => sub {
    _dist_results([qw(dist version)], $_[1]);
};

sub _dist_results {
    my ($fields, $res) = @_;
    for my $hit (@{ $res }) {
        div {
            class is 'res';
            h2 {
                a {
                    my @vals = map { $hit->{$_} } @{ $fields };
                    href is '/dist/' . lc join('/', @vals) . '/';
                    join ' ', @vals
                };
            };
            p { $hit->{excerpt} ? outs_raw $hit->{excerpt} : $hit->{abstract} };
            ul {
                li {
                    class is 'date';
                    (my $date = $hit->{date}) =~ s{T.+}{};
                    # Looking forward to HTML 5 in Template::Declare.
                    outs_raw qq{<time class="bday" datetime="$hit->{date}">$date</time>};
                };
                li {
                    class is 'user';
                    a {
                        href is lc "/user/$hit->{user}/";
                        title is T 'Released by [_1]', $hit->{user_name};
                        $hit->{user_name};
                    };
                };
            };
        }
    }
}

template 'results/tags' => sub {
    my $self = shift;
    for my $hit (@{ + shift }) {
        div {
            class is 'res';
            h2 {
                a {
                    href is lc "/tag/$hit->{tag}";
                    $hit->{tag}
                };
            };
        }
    }
};

template 'results/users' => sub {
    my $self = shift;
    for my $hit (@{ +shift }) {
        div {
            class is 'res';
            h2 {
                a {
                    href is lc "/user/$hit->{user}";
                    $hit->{user};
                };
            };
            p { outs_raw $hit->{name} };
        }
    }
};

template feedback => sub {
    my ($self, $req, $args) = @_;
    wrapper {
        div {
            id is 'info';
            div {
                class is 'gradient';
                outs_raw $l->from_file('feedback.html', _link_for_email($args->{feedback_to}));
            };
        };
    } $req, {
        title => _title_with T 'Feedback',
    };
};

template about => sub {
    my ($self, $req, $args) = @_;
    wrapper {
        div {
            id is 'info';
            div {
                class is 'gradient';
                outs_raw $l->from_file(
                    'about.html',
                    @{ $args->{stats} }{qw(extensions dists releases users tags mirrors)}
                );
            };
        };
    } $req, {
        title => _title_with T 'About PGXN',
    };
};

template donors => sub {
    my ($self, $req, $args) = @_;
    my $title = T 'Donors';
    wrapper {
        div {
            id is 'info';
            class is 'donors';
            div {
                class is 'gradient';
                h1 { $title };
                p { outs_raw T 'donors_intro' };

                h2 { T 'Founders' };
                show 'founders';

                h2 { T 'Patrons' };
                show 'patrons';

                h2 { T 'Benefactors' };
                show 'benefactors';

                div {
                    div {
                        class is 'width50 floatLeft';
                        h2 { T 'Sponsors' };
                        ul {
                            li { 'Richard Broersma' };
                            li {a{
                                href is 'http://tigerlead.com/';
                                'TigerLead';
                            }};
                            li { 'Thom Brown' };
                            li { 'Hitoshi Harada' };
                            li {a{
                                href is 'http://www.25th-floor.com/';
                                '25th-floor - de Pretis & Helmberger KG';
                            }};
                        };
                    };

                    div {
                        class is 'width50 floatRight';
                        h2 { T 'Advocates' };
                        ul {
                            li {a{
                                href is 'http://www.hubbellgrp.com/';
                                'Hubbell Group Inc.';
                            }};
                            li { 'John S. Gage' };
                            li {a{
                                href is 'http://www.2ndquadrant.us/';
                                'Greg Smith';
                            }};
                            li {a{
                                href is 'http://www.urbandb.com/';
                                'UrbanDB.com';
                            }};
                            li {a{
                                href is 'http://depesz.com/';
                                'depesz';
                            }};
                            li {a{
                                href is 'http://jim.nasby.net/';
                                'Jim Nasby';
                            }};
                            li {a{
                                href is 'http://www.progressivepractice.com/';
                                'Jon Erdman';
                            }};
                        };
                    };
                };

                div {
                    style is 'clear:both; padding-top: 2em;';
                    div {
                        class is 'width50 floatLeft';

                        h2 { T 'Supporters' };
                        ul {
                            li {a{
                                href is 'http://www.dagolden.com/';
                                'David Golden';
                            }};
                            li {a{
                                href is 'http://thoughts.j-davis.com/';
                                'Jeff Davis';
                            }};
                            li {a{
                                href is 'http://www.estately.com/';
                                'Estately';
                            }};
                            li {a{
                                href is 'http://www.full-table-scan.com/';
                                'Chris Spotts';
                            }};
                        };
                    };

                    div {
                        class is 'width50 floatRight';

                        h2 { T 'Boosters' };
                        ul {
                            li {a{
                                href is 'http://www.kineticode.com/';
                                'Kineticode, Inc.';
                            }};
                            li {a{
                                href is 'http://www.cxnet.cl/';
                                'CxNet (Chile)';
                            }};
                            li {a{
                                href is 'http://www.schemaverse.com/';
                                'Schemaverse';
                            }};
                            li {a{
                                href is 'http:/www.midstorm.org/~telles//';
                                'Fábio Telles Rodriguez';
                            }};
                            li {a{
                                href is 'http://www.nextbio.com/b/search/author/Wenjian%20Yang';
                                'Wenjian Yang';
                            }};
                            li {a{
                                href is 'http://pgdba.net/blog/';
                                'Michael Nacos';
                            }};
                            li { 'August Zajonc' };
                        };
                    };
                };
            };
        };
    } $req, {
        title => _title_with $title,
    };
};

template art => sub {
    my ($self, $req, $args) = @_;
    wrapper {
        div {
            id is 'info';
            div {
                class is 'gradient';
                outs_raw $l->from_file('art.html');
            };
        };
    } $req, {
        title => _title_with 'Identity',
    };
};

template faq => sub {
    my ($self, $req, $args) = @_;
    wrapper {
        div {
            id is 'info';
            div {
                class is 'gradient';
                outs_raw $l->from_file('faq.html');
            };
        };
    } $req, {
        title => _title_with 'FAQ',
    };
};

template mirroring => sub {
    my ($self, $req, $args) = @_;
    wrapper {
        div {
            id is 'info';
            div {
                class is 'gradient';
                outs_raw $l->from_file('mirroring.html', _obscure($args->{feedback_to}) . '?subject=Mirror Registration&amp;body=   &quot;mirror.hostname&quot;: {%0a      &quot;url&quot;:          &quot;http://hostname.of.the.pgxn/mirroring/site/root&quot;,%0a      &quot;frequency&quot;:    &quot;daily/bidaily/.../weekly&quot;,%0a      &quot;location&quot;:     &quot;city, (area?, )country, continent (lon lat)&quot;,%0a      &quot;organization&quot;: &quot;full organization name&quot;,%0a      &quot;timezone&quot;:     &quot;Area/Location zoneinfo tz&quot;,%0a      &quot;contact&quot;:      &quot;email.address.to.contact@for.this.mirror&quot;,%0a      &quot;bandwidth&quot;:    &quot;1Gbps, 100Mbps, DSL, etc.&quot;,%0a      &quot;src&quot;:          &quot;rsync://from.which.host/is/this/site/mirroring/from/&quot;,%0a      &quot;rsync&quot;:        &quot;rsync://hostname.of.the.mirror/path (if you provide it)&quot;,%0a      &quot;notes&quot;:        &quot;(optional field) access restrictions, for example?&quot;%0a   }%0a');
            };
        };
    } $req, {
        title => _title_with T 'Mirroring PGXN',
    };
};

my $err = sub {
    my ($req, $args) = @_;
    wrapper {
        div {
            class is 'width100 floatLeft';
            div {
                class is 'error gradient';
                h1 { $args->{title} };
                blockquote {
                    class is $args->{class};
                    p { $args->{message} };
                };
            };
        };
    } $req, {
        title => _title_with T $args->{title},
    };
};

template notfound => sub {
    my ($self, $req, $args) = @_;
    $err->($req => {
        class   => 'exclamation',
        title   => T('Not Found'),
        message => T('Resource not found.'),
    });
};

template badrequest => sub {
    my ($self, $req, $args) = @_;
    $err->($req => {
        class   => 'stop',
        title   => T('Bad Request'),
        message => T(
            'Bad request: Missing or invalid "[_1]" query parameter.',
            $args->{param}
        ),
    });
};

template servererror => sub {
    my ($self, $req, $args) = @_;
    $err->($req => {
        class   => 'stop',
        title   => T('Internal Server Error'),
        message => T('Internal server error.'),
    });
};

template search_form => sub {
    my ($self, $args) = @_;
    form {
        id is $args->{id};
        action is '/search';
        enctype is 'application/x-www-form-urlencoded';
        method is 'get';
        fieldset {
            class is 'query';
            input {
                type      is 'text';
                class     is 'width50';
                name      is 'q';
                autofocus is 'autofocus' if $args->{autofocus};
                value     is $args->{query};
            };
        }; # /fieldset.query
        fieldset {
            class is 'submitin';
            label { attr { id is 'inlabel'; for => 'searchin' }; T 'in' };
            select {
                id is 'searchin';
                name is 'in';
                my $in = $args->{in};
                for my $spec (
                    [ docs       => 'Documentation' ],
                    [ extensions => 'Extensions'    ],
                    [ dists      => 'Distributions' ],
                    [ users      => 'Users'         ],
                    [ tags       => 'Tags'          ]
                ) {
                    option {
                        value is $spec->[0];
                        selected is 'selected' if $in eq $spec->[0];
                        T $spec->[1];
                    };
                }
            };
            input {
                type  is 'submit';
                value is T 'PGXN Search';
                class is 'button';
            };
        }; # /fieldset.submitin
    }; # /form#resultsearch
};

template release_table => sub {
    my ($self, $req, $rel, $args) = @_;
    my $api  = $args->{api};
    my $user = $args->{user};
    div {
        class is 'gradient dists';
        h3 { T 'Distributions' };
        if (%{ $rel }) {
        table { tbody {
            for my $dist (sort keys %{ $rel }) {
                my $status = first { $rel->{$dist}{$_} } qw(stable testing unstable);
                my $info   = $rel->{$dist}{$status}[0];
                row {
                    class is 'dist';
                    cell {
                        class is 'name';
                        a {
                            class is 'url';
                            href is lc "/dist/$dist" . ($user ? "/$info->{version}/" : '/');
                            span { class is 'fn'; $dist };
                            span { class is 'version'; $info->{version} };
                            span { class is 'status'; "($status)" } if $status ne 'stable';
                        };
                    };
                    cell {
                        class is 'abstract';
                        $rel->{$dist}{abstract};
                    };
                    cell {
                        class is 'bday';
                        (my $date = $info->{date}) =~ s{T.+}{};
                        # Looking forward to HTML 5 in Template::Declare.
                        outs_raw qq{<time class="bday" datetime="$info->{date}">$date</time>};
                    };
                    cell {
                        class is 'browse';
                        a {
                            class is 'url';
                            href is URI->new($args->{api_url} . $api->source_path_for($dist => $info->{version}));
                            title is T 'Browse [_1] [_2]', $dist, $info->{version};
                            img {
                                src is '/ui/img/package.png';
                                alt is T 'Browse';
                            };
                        }
                    };
                    cell {
                        class is 'download';
                        a {
                            class is 'url';
                            href is URI->new($args->{api_url} . $api->download_path_for($dist => $info->{version}));
                            title is T 'Download [_1] [_2]', $dist, $info->{version};
                            img {
                                src is '/ui/img/download.png';
                                alt is T 'Download';
                            };
                        };
                    };
                }; # /tr.dist
            }
        } }; # /table
    } else {
        p {
            class is 'alas';
            T 'Alas, [_1] has yet to release a distribution.', $user->nickname;
        } if $user;
    }
    }; # /div.gradient dists
};

template founders => sub {
    div {
        id is 'founders';
        a {
            href is 'http://www.myyearbook.com/';
            title is 'myYearbook';
            img {
                src is '/ui/img/myyearbook.png';
                alt is 'myYearbook.com';
            };
        };
        a {
            href is 'http://www.pgexperts.com/';
            title is 'PostgreSQL Experts, Inc.';
            img {
                src is '/ui/img/pgexperts.png';
                alt is 'PGX';
            };
        };
        a {
            href is 'http://www.dalibo.org/en/';
            title is 'Dalibo';
            img {
                src is '/ui/img/dalibo.png';
                alt is 'Dalibo';
            };
        };
    };
};

template patrons => sub {
    div {
        id is 'patrons';
        h3 {
            a {
                href is 'http://www.enovafinancial.com/';
                title is 'Enova Financial';
                img {
                    src is '/ui/img/enova.png';
                    alt is 'e';
                };
                outs ' Enova Financial';
            };
        };
    };
};

template benefactors => sub {
    ul {
        id is 'benefactors';
        for my $spec (
            [ 'http://www.etsy.com/'          => 'Etsy'                       ],
            [ 'http://www.postgresql.us/'     => 'US PostgreSQL Association'  ],
            [ 'http://www.commandprompt.com/' => 'Command Prompt, Inc.'       ],
            [ 'http://www.marchex.com/'       => 'Marchex'                    ],
            [ 'http://younicycle.com/'        => 'Younicycle, The Web System' ],
        ) {
            li { a { href is $spec->[0]; $spec->[1] } };
        }
    };
};

my %class_for = (
    agpl_3       => 'AGPL_3',
    apache_1_1   => 'Apache_1_1',
    apache_2_0   => 'Apache_2_0',
    artistic_1   => 'Artistic_1_0',
    artistic_2   => 'Artistic_2_0',
    bsd          => 'BSD',
    freebsd      => 'FreeBSD',
    gfdl_1_2     => 'GFDL_1_2',
    gfdl_1_3     => undef,
    gpl_1        => 'GPL_1',
    gpl_2        => 'GPL_2',
    gpl_3        => 'GPL_3',
    lgpl_2_1     => 'LGPL_2_1',
    lgpl_3_0     => 'LGPL_3_0',
    mit          => 'MIT',
    mozilla_1_0  => 'Mozilla_1_0',
    mozilla_1_1  => 'Mozilla_1_1',
    openssl      => 'OpenSSL',
    perl_5       => 'Perl_5',
    postgresql   => 'PostgreSQL',
    qpl_1_0      => 'QPL_1_0',
    ssleay       => 'SSLeay',
    sun          => 'Sun',
    zlib         => 'Zlib',
);

sub _license($) {
    my $class = $class_for{+shift} or return;
    $class = "Software::License::$class";
    eval "require $class; 1" or die;
    return $class;
}

sub _link_for_email {
    my $email = shift;
    return '<a href="'
        . _obscure(URI->new("mailto:$email"))
        . '">' . _obscure($email)
        . '</a>';
};

sub _obscure ($) {
#
#   Input: an email address, e.g. "foo@example.com"
#
#   Output: the email address as a mailto link, with each character
#       of the address encoded as either a decimal or hex entity, in
#       the hopes of foiling most address harvesting spam bots. E.g.:
#
#     <a href="&#x6D;&#97;&#105;&#108;&#x74;&#111;:&#102;&#111;&#111;&#64;&#101;
#       x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;">&#102;&#111;&#111;
#       &#64;&#101;x&#x61;&#109;&#x70;&#108;&#x65;&#x2E;&#99;&#111;&#109;</a>
#
#   Based on a filter by Matthew Wickline, posted to the BBEdit-Talk
#   mailing list: <http://tinyurl.com/yu7ue>
#
    my $addr = shift;

    my @encode = (
        sub { '&#' .                 ord(shift)   . ';' },
        sub { '&#x' . sprintf( "%X", ord(shift) ) . ';' },
        sub {                            shift          },
    );

    $addr =~ s{(.)}{
        my $char = $1;
        if ( $char eq '@' ) {
            # this *must* be encoded. I insist.
            $char = $encode[int rand 1]->($char);
        }
        elsif ( $char ne ':' ) {
            # leave ':' alone (to spot mailto: later)
            my $r = rand;
            # roughly 10% raw, 45% hex, 45% dec
            $char = (
                $r > .9   ?  $encode[2]->($char)  :
                $r < .45  ?  $encode[1]->($char)  :
                             $encode[0]->($char)
            );
        }
        $char;
    }gex;

    return $addr;
}

=head1 Name

PGXN::Site::Templates - HTML templates for PGXN::Site

=head1 Synopsis

  use PGXN::Site::Templates;
  Template::Declare->init( dispatch_to => ['PGXN::Site::Templates'] );
  print Template::Declare->show('home', $req, {
      title   => 'PGXN::Site',
  });

=head1 Description

This class defines the HTML templates used by PGXN::Site. They are used
internally by L<PGXN::Site::Controller> to render the UI. They're implemented
with L<Template::Declare>, but interface wise, all you need to do is C<show>
them as in the L</Synopsis>.

=head1 Templates

=head2 Wrapper

=head3 C<wrapper>

Wrapper template called by all page view templates that wraps them in the
basic structure of the site (logo, navigation, footer, etc.). It also handles
the title of the site, and any status message or error message. These must be
stored under the C<title>, C<status_msg>, and C<error_msg> keys in the args
hash, respectively.

=begin comment

XXX Document all parameters.

=end comment

=head2 Full Page Templates

=head3 C<home>

Renders the home page of the app.

=head2 Utility Functions

=head3 C<T>

  h1 { T 'Welcome!' };

Translates the string using L<PGXN::Site::Locale>.

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2010-2013 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut
