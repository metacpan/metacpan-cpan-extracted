use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::ProgressBar;
use Moonshine::Bootstrap::v3::ProgressBar;

moon_test(
    name => 'progress_bar',
    build => {
        class => 'Moonshine::Bootstrap::Component::ProgressBar',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'progress_bar',
            args   => { aria_valuenow => '60' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar"><span class="sr-only">60%</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            args   => { aria_valuenow => '60', show => 1 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            args   => { aria_valuenow => '60', show => 1, switch => 'success' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-success" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => { aria_valuenow => '60', show => 1, switch => 'info' },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-info" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => { aria_valuenow => '60', show => 1, switch => 'warning' },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-warning" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => { aria_valuenow => '60', show => 1, switch => 'danger' },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-danger" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => {
                aria_valuenow => '60',
                show          => 1,
                switch        => 'danger',
                striped       => 1
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-danger progress-bar-striped" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => {
                aria_valuenow => '60',
                show          => 1,
                switch        => 'danger',
                striped       => 1,
                active      => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-danger active progress-bar-striped" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
    ],
);

moon_test(
    name => 'progress_bar',
    build => {
        class => 'Moonshine::Bootstrap::v3::ProgressBar',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'progress_bar',
            args   => { aria_valuenow => '60' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar"><span class="sr-only">60%</span></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            args   => { aria_valuenow => '60', show => 1 },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            args   => { aria_valuenow => '60', show => 1, switch => 'success' },
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-success" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => { aria_valuenow => '60', show => 1, switch => 'info' },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-info" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => { aria_valuenow => '60', show => 1, switch => 'warning' },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-warning" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => { aria_valuenow => '60', show => 1, switch => 'danger' },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-danger" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => {
                aria_valuenow => '60',
                show          => 1,
                switch        => 'danger',
                striped       => 1
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-danger progress-bar-striped" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress_bar',
            expected => 'Moonshine::Element',
            args   => {
                aria_valuenow => '60',
                show          => 1,
                switch        => 'danger',
                striped       => 1,
                active      => 1,
            },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress-bar progress-bar-danger active progress-bar-striped" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar">60%</div>',
                }
            ],
        },
    ],
);


sunrise();
