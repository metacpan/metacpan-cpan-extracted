Net::Zendesk
============

Net::Zendesk is a thin and lightweight interface for Zendesk's API.

```perl
    use Net::Zendesk;

    my $zen = Net::Zendesk->new(
        domain => 'obscura.zendesk.com',
        email  => 'yourvaliduser@example.com',
        token  => 'your_valid_zendesk_api_token',
    );

    $zen->create_ticket(
        {
            requester => {
                name  => 'The Customer',
                email => 'thecustomer@example.com',
            },
            subject => 'My printer is on fire!',
            comment => {
                body => 'The smoke is very colorful.'
            },
        },
        async => 'true',
    );

    my $result = $zen->search({
        status   => 'open',
        priority => { '>=' => 'normal' },
        created  => { '>' => '2017-01-23', '<' => '2017-03-01' },
        subject  => 'photo*',
        assignee => undef,
        -tags    => 'invoice',
    });
```

For complete usage information, please refer to the
[full documentation](https://metacpan.org/pod/Net::Zendesk).

### Installation

    cpanm Net::Zendesk

or

    cpan Net::Zendesk

or, manually:

    perl Makefile.PL && make && make test && make install

### Author

Breno G. de Oliveira `garu at cpan.org`
