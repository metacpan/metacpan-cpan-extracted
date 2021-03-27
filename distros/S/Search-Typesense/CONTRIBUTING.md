# How to Help

## Quickstart

If you have Perl v5.16.0 (or higher) and docker installed:

    git clone git@github.com:Ovid/Search-Typesense.git Mojo::UserAgent::Mockable
    cd Search-Typesense
    cpan autodie Mojo::UserAgent::Mockable Mojolicious Moo Test::Most Test::Perl::Critic Test::PerlTidy Type::Tiny
    # or
    cpanm autodie Mojo::UserAgent::Mockable Mojolicious Moo Test::Most Test::Perl::Critic Test::PerlTidy Type::Tiny

Alternatively, if you're using `Dist::Zilla`:

    dzil listdeps --missing --author --cpanm-versions | cpanm

Then just run the tests:

    prove -rl t

If you wish to run tests against a Typesense server:

    docker run                           \
          -p 7777:8108 -v/tmp:/data      \
          typesense/typesense:0.19.0     \
          --data-dir /data --api-key=777
    PERL_TEST_TYPESENSE_MODE=devel prove -rl t

If you get through all of the above steps and the `prove` command output ends
with `Result: PASS`, you're good to go.

## Getting Started

You'll need to get Typesense up and running and then run the tests.

### Configuring Typesense

The tests don't require Typesense to be running unless
`PERL_TEST_TYPESENSE_MODE` is set to `devel`. Then, the tests assume Typesense
is running on a non-standard port, 7777, with the api key of 777.

If you use docker, you can get Typesense up and running with:

    docker run \
        -p 7777:8108 -v/tmp:/data \
        typesense/typesense:0.19.0 \
        --data-dir /data --api-key=777

We run tests on docker with a non-standard port to minimize the chance of
interfering with a live installation (though it's still possible).

### Running the Tests

If you wish to run the tests against a real Typesense server, do this:

    PERL_TEST_TYPESENSE_MODE=devel prove -l t
    PERL_TEST_TYPESENSE_MODE=devel prove -lv t   # verbose mode

If you with to regenerate the cached test fixtures:

    PERL_TEST_TYPESENSE_MODE=record prove -l t

Note that by default, if you change any of the `t/*.t` files, the fixtures
for the changed files will be automatically regenerated.

### Start Hacking

Once you have the tests passing, you're good to start.

Create a new branch, via `git checkout -b branch-name` and start hacking. When
you're done, just issue a pull request.

If you're wondering what you can hack on, see the `TODO` section below.

## TODO

There are quite a few things we would like to have for this module.

### Additional Features

* [Federated / Multisearch](https://typesense.org/docs/0.19.0/api/documents.html#federated-multi-search)
* [Delete by Query](https://typesense.org/docs/0.19.0/api/documents.html#delete-by-query)
* [CSV Imports](https://typesense.org/docs/0.19.0/api/documents.html#import-a-csv-file)
* [Configuring import batch size](https://typesense.org/docs/0.19.0/api/documents.html#configure-batch-size)
* [API key management](https://typesense.org/docs/0.19.0/api/api-keys.html)
* [Curated Documents](https://typesense.org/docs/0.19.0/api/curation.html)
* [Aliases](https://typesense.org/docs/0.19.0/api/collection-alias.html)
* [Synonyms](https://typesense.org/docs/0.19.0/api/synonyms.html)
* [Cluster Operations](https://typesense.org/docs/0.19.0/api/cluster-operations.html)

### Transfer

I would like this to work:

    $typesense1->transfer_data( to   => $typesense2 );
    $typesense1->transfer_data( from => $typesense2 );

The above is very useful when migrating a Typesense server to another
platform.

Internally, it would probably do something like this pseudo-code:

    foreach collection in typesense1->collections:
        typesense2->import(collection->export)

This shouldn't be too hard, it will require two Typesense test servers. We
also don't want to try to transfer data from a typesene server to itself.

### More Documentation

Many places in the docs refer you back to the official Typesense
documentation. It would be lovely if we could have more full-featured examples
in the POD.

### INI File Support

It would be nice to allow this:

    my $typesense = Search::Typesense->new( config => 'typesense.ini' );

### More Tests

In addition to the above, we love far more tests (especially covering
failures). We also rely on a test Typesense server being up and running (see
"Configuring Typesense" above). It would be nice to have a fallback strategy
if a live server isn't available, but this becomes a headache as features
sometimes change between Typesense versions.

### Version Checking

We have an internal version object. It would be nice to use that to test if
a feature can work. For example, if we add Federated/Multisearch, we should
`warn` or `croak` if someone requests this on a version less than `0.19.0`.

### Make Tests Configurable

If, for some reason, you can't use the `docker` example above to get a test
instance of Typesense running, we might want to configure
`t/lib/Test/Search/Typesense.pm` to recognize environment variables to point
at a test instance of Typesense that you've already set up. However, the test
suite runs `$typesense->collections->delete_all`, so this will **destroy**
your Typesense data. This is definitely a "proceed with caution" area.

# Dist::Zilla

This distribution, as mentioned, uses Dist::Zilla for deploying. If you don't
know what that is, don't worry about it. If you do know what that is and want
to play around, you can install all deps with:

    dzil authordeps --missing | cpanm
