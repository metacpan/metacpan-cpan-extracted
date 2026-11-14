
Set(%Lifecycles,
    'aws-assets' => {
        type     => "asset",
        initial  => [ 
            'new' # loc
        ],
        active   => [ 
            'running', # loc
            'stopped', # loc
            'not-found', # loc
        ],
        inactive => [ 
            'removed', # loc
            'deleted' # loc
        ],

        defaults => {
            on_create => 'new',
        },

        transitions => {
            ''        => [qw(new running stopped)],
            new       => [qw(running stopped not-found removed deleted)],
            running   => [qw(new stopped not-found removed deleted)],
            stopped   => [qw(new running not-found removed deleted)],
            'not-found' => [qw(new running stopped removed deleted)],
            removed   => [qw(new running stopped deleted)],
            deleted   => [qw(new running stopped removed)],
        },
        rights => {
            '* -> *'        => 'ModifyAsset',
        },
        actions => [
            '* -> running' => { 
                label => "Running" # loc
            },
            '* -> stopped' => {
                label => "Stopped" # loc
            },
            '* -> not-found'    => { 
                label => "Not Found" # loc
            },
            '* -> deleted'  => { 
                label => "Delete" # loc
            },
        ],
    },
    'aws-reservations' => {
        type     => "asset",
        initial  => [ 
            'new' # loc
        ],
        active   => [ 
            'payment-pending', # loc
            'active' # loc
        ],
        inactive => [ 
            'retired', # loc
            'deleted' # loc
        ],

        defaults => {
            on_create => 'new',
        },

        transitions => {
            ''        => [qw(new payment-pending active)],
            new       => [qw(payment-pending active retired deleted)],
            'payment-pending' => [qw(new active retired deleted)],
            active    => [qw(new payment-pending retired deleted)],
            retired   => [qw(new payment-pending active deleted)],
            deleted   => [qw(active retired)],
        },
        rights => {
            '* -> *'        => 'ModifyAsset',
        },
        actions => [
            '* -> active' => { 
                label => "Activate" # loc
            },
            '* -> retired'    => { 
                label => "Retire" # loc
            },
            '* -> deleted'  => { 
                label => "Delete" # loc
            },
        ],
    },
);

1;
