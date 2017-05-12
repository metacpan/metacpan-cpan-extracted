use Moonshine::Test qw/:all/;

use Moonshine::Bootstrap::Component::Progress;
use Moonshine::Bootstrap::v3::Progress;

moon_test(
    name => 'progress',
    build => {
        class => 'Moonshine::Bootstrap::Component::Progress',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'progress',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress"></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress',
            expected => 'Moonshine::Element',
            args   => { bar => { aria_valuenow => '60' } },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress"><div class="progress-bar" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar"><span class="sr-only">60%</span></div></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress',
            expected => 'Moonshine::Element',
            args   => { stacked => [
				{ aria_valuenow => '35', show => 1, switch => 'success' },
				{ aria_valuenow => '20', striped => 1 },
				{ aria_valuenow => '10', switch => 'danger' },
			]},
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress"><div class="progress-bar progress-bar-success" style="min-width:3em; width:35%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="35" role="progressbar">35%</div><div class="progress-bar progress-bar-striped" style="min-width:3em; width:20%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="20" role="progressbar"><span class="sr-only">20%</span></div><div class="progress-bar progress-bar-danger" style="min-width:3em; width:10%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="10" role="progressbar"><span class="sr-only">10%</span></div></div>'
                }
            ],
        },
    ],
);

moon_test(
    name => 'progress',
    build => {
        class => 'Moonshine::Bootstrap::v3::Progress',        
    },
    instructions => [
        {
            test => 'obj',
            func => 'progress',
            expected => 'Moonshine::Element',
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress"></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress',
            expected => 'Moonshine::Element',
            args   => { bar => { aria_valuenow => '60' } },
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress"><div class="progress-bar" style="min-width:3em; width:60%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="60" role="progressbar"><span class="sr-only">60%</span></div></div>',
                }
            ],
        },
        {
            test => 'obj',
            func => 'progress',
            expected => 'Moonshine::Element',
            args   => { stacked => [
				{ aria_valuenow => '35', show => 1, switch => 'success' },
				{ aria_valuenow => '20', striped => 1 },
				{ aria_valuenow => '10', switch => 'danger' },
			]},
            subtest => [
                {
                    test => 'render',
                    expected => '<div class="progress"><div class="progress-bar progress-bar-success" style="min-width:3em; width:35%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="35" role="progressbar">35%</div><div class="progress-bar progress-bar-striped" style="min-width:3em; width:20%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="20" role="progressbar"><span class="sr-only">20%</span></div><div class="progress-bar progress-bar-danger" style="min-width:3em; width:10%;" aria-valuemax="100" aria-valuemin="0" aria-valuenow="10" role="progressbar"><span class="sr-only">10%</span></div></div>'
                }
            ],
        },
    ],
);

sunrise();
