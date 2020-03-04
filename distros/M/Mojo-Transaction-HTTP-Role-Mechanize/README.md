<div>
    <a href="https://travis-ci.com/kiwiroy/mojo-transaction-http-role-mechanize">
      <img alt="Travis Build Status"
           src="https://travis-ci.com/kiwiroy/mojo-transaction-http-role-mechanize.svg?branch=master" />
    </a>
    <a href="https://kritika.io/users/kiwiroy/repos/7509235145731088/heads/master/">
      <img alt="Kritika Analysis Status"
           src="https://kritika.io/users/kiwiroy/repos/7509235145731088/heads/master/status.svg?type=score%2Bcoverage%2Bdeps" />
    </a>
    <a href="https://coveralls.io/github/kiwiroy/mojo-transaction-http-role-mechanize?branch=master">
      <img alt="Coverage Status"
           src="https://coveralls.io/repos/github/kiwiroy/mojo-transaction-http-role-mechanize/badge.svg?branch=master" />
    </a>
    <a href="https://badge.fury.io/pl/Mojo-Transaction-HTTP-Role-Mechanize">
      <img alt="CPAN version" height="18"
           src="https://badge.fury.io/pl/Mojo-Transaction-HTTP-Role-Mechanize.svg" />
    </a>
</div>

# NAME

Mojo::Transaction::HTTP::Role::Mechanize - Mechanize Mojo a little

# SYNOPSIS

    use Mojo::UserAgent;
    use Mojo::Transaction::HTTP::Role::Mechanize;

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get('/')->with_roles('+Mechanize');

    # call submit immediately
    my $submit_tx = $tx->submit('#submit-id', username => 'fry');
    $ua->start($submit_tx);

    # first extract form values
    my $values = $tx->extract_forms->first->val;
    $submit_tx = $tx->submit('#submit-id', counter => $values->{counter} + 3);
    $ua->start($submit_tx);

# DESCRIPTION

[Role::Tiny](https://metacpan.org/pod/Role%3A%3ATiny) based role to compose a form submission _"trait"_ into
[Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo%3A%3ATransaction%3A%3AHTTP).

# METHODS

[Mojo::Transaction::HTTP::Role::Mechanize](https://metacpan.org/pod/Mojo%3A%3ATransaction%3A%3AHTTP%3A%3ARole%3A%3AMechanize) implements the following method.

## extract\_forms

    $collection = $tx->extract_forms;

Returns a [Mojo::Collection](https://metacpan.org/pod/Mojo%3A%3ACollection) of [Mojo::DOM](https://metacpan.org/pod/Mojo%3A%3ADOM) elements with activated [Mojo::DOM::Role::Form](https://metacpan.org/pod/Mojo%3A%3ADOM%3A%3ARole%3A%3AForm)
that contains all the forms of the page.

## submit

    # result using selector
    $submit_tx = $tx->submit('#id', username => 'fry');

    # result without selector using default submission
    $submit_tx = $tx->submit(username => 'fry');

    # passing hash, rather than list, of values
    $submit_tx = $tx->submit({username => 'fry'});

    # passing hash, rather than list, of values and a selector
    $submit_tx = $tx->submit('#id', {username => 'fry'});

Build a new [Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo%3A%3ATransaction%3A%3AHTTP) object with
["tx" in Mojo::UserAgent::Transactor](https://metacpan.org/pod/Mojo%3A%3AUserAgent%3A%3ATransactor#tx) and the contents of the `form` with the
`$id` and merged values.  If no selector is given, the first non-disabled
button or appropriate input element (of type button, submit, or image)
will be used for the submission.

# AUTHOR

kiwiroy - Roy Storey `kiwiroy@cpan.org`

# CONTRIBUTORS

tekki - Rolf Stöckli `tekki@cpan.org`

lindleyw - William Lindley `wlindley+remove+this@wlindley.com`

# LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

# SEE ALSO

[Mojo::DOM::Role::Form](https://metacpan.org/pod/Mojo%3A%3ADOM%3A%3ARole%3A%3AForm), [Mojolicious](https://metacpan.org/pod/Mojolicious).
