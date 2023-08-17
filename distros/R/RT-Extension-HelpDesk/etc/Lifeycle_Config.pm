Set(%Lifecycles,
    support => {
        initial       => [qw(new)], # loc_qw
        active        => [qw(open stalled), 'waiting for support', 'waiting for customer'], # loc_qw
        inactive      => [qw(resolved rejected deleted)], # loc_qw

        defaults => {
            on_create => 'new',
            approved  => 'open',
            denied    => 'rejected',
            reminder_on_open     => 'open',
            reminder_on_resolve  => 'resolved',
        },

        transitions => {
            ""       => [qw(new open resolved)],

            # from   => [ to list ],
            new      => [qw(    open stalled resolved rejected deleted), 'waiting for support', 'waiting for customer'],
            open     => [qw(new      stalled resolved rejected deleted), 'waiting for support', 'waiting for customer'],
            stalled  => [qw(new open         resolved rejected deleted), 'waiting for support', 'waiting for customer'],
            resolved => [qw(new open stalled          rejected deleted), 'waiting for support', 'waiting for customer'],
            rejected => [qw(new open stalled resolved          deleted), 'waiting for support', 'waiting for customer'],
            deleted  => [qw(new open stalled resolved rejected        )],
            'waiting for support'  => [qw(open stalled resolved rejected deleted), 'waiting for customer'],
            'waiting for customer' => [qw(open stalled resolved rejected deleted), 'waiting for support'],
        },
        rights => {
            '* -> deleted'  => 'DeleteTicket',
            '* -> *'        => 'ModifyTicket',
        },
        actions => [
            'new -> open'      => { label  => 'Open It', update => 'Respond' }, # loc{label}
            'new -> resolved'  => { label  => 'Resolve', update => 'Comment' }, # loc{label}
            'new -> rejected'  => { label  => 'Reject',  update => 'Respond' }, # loc{label}
            'new -> deleted'   => { label  => 'Delete',                      }, # loc{label}
            'open -> stalled'  => { label  => 'Stall',   update => 'Comment' }, # loc{label}
            'open -> resolved' => { label  => 'Resolve', update => 'Comment' }, # loc{label}
            'open -> rejected' => { label  => 'Reject',  update => 'Respond' }, # loc{label}
            'stalled -> open'  => { label  => 'Open It',                     }, # loc{label}
            'resolved -> open' => { label  => 'Re-open', update => 'Comment' }, # loc{label}
            'rejected -> open' => { label  => 'Re-open', update => 'Comment' }, # loc{label}
            'deleted -> open'  => { label  => 'Undelete',                    }, # loc{label}
        ],
    },
     __maps__ => {
        'default -> support' => {
            'stalled'  => 'waiting for customer',
            'new'      => 'new',
            'open'     => 'open',
            'resolved' => 'resolved',
            'rejected' => 'rejected',
            'deleted'  => 'deleted',
        },
        'support -> default' => {
            'waiting for support'  => 'stalled',
            'waiting for customer' => 'stalled',
            'new'      => 'new',
            'open'     => 'open',
            'resolved' => 'resolved',
            'rejected' => 'rejected',
            'deleted'  => 'deleted',
        }
     }
);
