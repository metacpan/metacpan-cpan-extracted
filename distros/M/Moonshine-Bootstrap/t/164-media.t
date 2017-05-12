use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Media;
use Moonshine::Bootstrap::v3::Media;

moon_test(
    name => 'media',
    build => {
        class => 'Moonshine::Bootstrap::Component::Media',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'media',
            expected => 'Moonshine::Element',
            args   => {
                children => [
                    {
                        action => 'media_object',
                        x      => 'left',
                        y      => 'middle',
                        children  => [
                            {
                                action => 'media_link_image',
                                href   => "#",
                                img    => { src => 'url', alt => 'alt text' },
                            }
                        ],
                    },
                    {
                        action => 'media_object',
                        body   => 1,
                        children  => [
                            {
                                action => 'h4',
                                class  => 'media-heading',
                                data   => "Middle aligned media",
                            }
                        ],
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="media"><div class="media-left media-middle"><a href="#"><img alt="alt text" class="media-object" src="url"></img></a></div><div class="media-body"><h4 class="media-heading">Middle aligned media</h4></div></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'media',
    build => {
        class => 'Moonshine::Bootstrap::v3::Media',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'media',
            expected => 'Moonshine::Element',
            args   => {
                children => [
                    {
                        action => 'media_object',
                        x      => 'left',
                        y      => 'middle',
                        children  => [
                            {
                                action => 'media_link_image',
                                href   => "#",
                                img    => { src => 'url', alt => 'alt text' },
                            }
                        ],
                    },
                    {
                        action => 'media_object',
                        body   => 1,
                        children  => [
                            {
                                action => 'h4',
                                class  => 'media-heading',
                                data   => "Middle aligned media",
                            }
                        ],
                    }
                ],
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="media"><div class="media-left media-middle"><a href="#"><img alt="alt text" class="media-object" src="url"></img></a></div><div class="media-body"><h4 class="media-heading">Middle aligned media</h4></div></div>'
                }
            ],
        },
    ],
);


sunrise();
