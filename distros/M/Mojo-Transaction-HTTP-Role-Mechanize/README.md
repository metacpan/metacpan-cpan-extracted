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
</div>

# NAME

Mojo::Transaction::HTTP::Role::Mechanize - Mechanize Mojo a little

# SYNOPSIS

    # description
    my $tx = $ua->get('/')->with_roles('+Mechanize');
    my $submit_tx = $tx->submit('#submit-id', username => 'fry');
    $ua->start($submit_tx);

# DESCRIPTION

[Role::Tiny](https://metacpan.org/pod/Role::Tiny) based role to compose a form submission _"trait"_ into
[Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo::Transaction::HTTP).

# METHODS

[Mojo::Transaction::HTTP::Role::Mechanize](https://metacpan.org/pod/Mojo::Transaction::HTTP::Role::Mechanize) implements the following method.

## submit

    # result using selector
    $submit_tx = $tx->submit('#id', username => 'fry');
    # result without selector using default submission
    $submit_tx = $tx->submit(username => 'fry');
    # passing hash, rather than list, of values
    $submit_tx = $tx->submit({username => 'fry'});
    # passing hash, rather than list, of values and a selector
    $submit_tx = $tx->submit('#id', {username => 'fry'});

Build a new [Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo::Transaction::HTTP) object with
["tx" in Mojo::UserAgent::Transactor](https://metacpan.org/pod/Mojo::UserAgent::Transactor#tx) and the contents of the `form` with the
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
