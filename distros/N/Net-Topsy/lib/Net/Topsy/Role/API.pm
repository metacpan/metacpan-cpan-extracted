package Net::Topsy::Role::API;

use Moose::Role;

has API => ( isa => 'HashRef', is => 'ro', default => sub {
        {
        'http://otter.topsy.com' => {
            '/search' => {
                args       => {
                    q       => 1,
                    window  => 0,
                    page    => 0,
                    perpage => 0,
                },
            },
            '/searchcount' => {
                args       => {
                    q       => 1,
                },
            },
            '/profilesearch' => {
                args       => {
                    q       => 1,
                    page    => 0,
                    perpage => 0,
                },
            },
            '/authorsearch' => {
                args       => {
                    q       => 1,
                    window  => 0,
                    page    => 0,
                    perpage => 0,
                },
            },
            '/stats' => {
                args       => {
                    url       => 1,
                    contains  => 0,
                },
            },
            '/tags' => {
                args       => {
                    url       => 1,
                    page    => 0,
                    perpage => 0,
                },
            },
            '/authorinfo' => {
                args       => {
                    url       => 1,
                },
            },
            '/urlinfo' => {
                args       => {
                    url       => 1,
                },
            },
            '/linkposts' => {
                args       => {
                    url       => 1,
                    contains => 0,
                    page    => 0,
                    perpage => 0,
                },
            },
            '/trending' => {
                args       => {
                    page    => 0,
                    perpage => 0,
                },
            },
            '/credit' => {
                args       => {
                },
            },
            '/trackbacks' => {
                args       => {
                    url      => 1,
                    contains => 0,
                    infonly  => 0,
                    page     => 0,
                    perpage  => 0,
                },
            },
            '/related' => {
                args       => {
                    url     => 1,
                    page    => 0,
                    perpage => 0,
                },
            },
            '/trackbackcount' => {
                args       => {
                    url      => 1,
                    contains => 0,
                },
            },
        },
    },
});

1;
