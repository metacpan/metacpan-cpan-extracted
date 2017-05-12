Net::HTTP::Spore::Middleware::BaseUrl
=====================================

Spore Middleware to change the base_url on the fly

```perl
    my $client = Net::HTTP::Spore->new_from_spec('api.json');
    $client->enable( 'BaseUrl',
        base_url  => 'http://www.perl.org'
    );
```