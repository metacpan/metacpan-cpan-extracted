# Mojolicious::Plugin::Restify [![Build Status](https://travis-ci.org/kwakwaversal/mojolicious-plugin-restify.svg?branch=master)](https://travis-ci.org/kwakwaversal/mojolicious-plugin-restify)

Route shortcuts & helpers for REST collections for the
[Mojolicious](http://mojolicio.us) web framework.

```perl
  # Mojolicious example (Mojolicious::Lite isn't supported)
  package MyApp;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;

    # imports the `collection' route shortcut and `restify' helpers
    $self->plugin('Restify');

    # add REST collection endpoints manually
    my $r = $self->routes;
    my $accounts = $r->collection('accounts');      # /accounts
    $accounts->collection('invoices');              # /accounts/:accounts_id/invoices

    # or add the equivalent REST routes with an ARRAYREF (the helper will
    # create chained routes from the path 'accounts/invoices' so you don't need
    # to set ['accounts', 'accounts/invoices'])
    my $r = $self->routes;
    $self->restify->routes($r, ['accounts/invoices']);

    # or add the equivalent REST routes with a HASHREF (might be easier to
    # visualise how collections are chained together)
    my $r = $self->routes;
    $self->restify->routes($r, {
      accounts => {
        invoices => undef
      }
    });
  }
```

Next create your controller for accounts.

```perl
  # Restify controller depicting the REST actions for the /accounts collection.
  # (The name of the controller is the Mojo::Util::camelized version of the
  # collection path.)
  package MyApp::Controller::Accounts;
  use Mojo::Base 'Mojolicious::Controller';

  sub resource_lookup {
    my $c = shift;

    # To consistenly get the element's ID relative to the resource_lookup
    # action, use the helper as shown below. If you need to access an element ID
    # from a collection further up the chain, you can access it from the stash.
    #
    # The naming convention is the name of the collection appended with '_id'.
    # E.g., $c->stash('accounts_id').
    my $account = your_lookup_account_resource_func($c->restify->current_id);

    # By stashing the $account here, it will now be available in the delete,
    # read, patch, and update actions. This resource_lookup action is optional,
    # but added to every collection by default to help reduce your code.
    $c->stash(account => $account);

    # must return a positive value to continue the dispatch chain
    return 1 if $account;

    # inform the end user that this specific resource does not exist
    $c->reply->not_found and return 0;
  }

  sub create { ... }

  sub delete { ... }

  sub list { ... }

  sub read {
    my $c = shift;

    # account was placed in the stash in the resource_lookup action
    $c->render(json => $c->stash('account'));
  }

  sub patch { ... }

  sub update { ... }

  1;
```

[Mojolicious::Plugin::Restify](https://metacpan.org/release/Mojolicious-Plugin-Restify)
is a [Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin). It
simplifies generating all of the
[Mojolicious::Routes](https://metacpan.org/pod/Mojolicious::Routes) for a
typical REST *collection* endpoint (e.g., `/accounts` or `/invoices>` and maps
the common HTTP verbs (`DELETE`, `GET`, `PATCH`, `POST`, `PUT>` to underlying
controller class methods.

For example, creating a *collection* called `/accounts` would create the routes
as shown below. N.B. The `over` option in the example below corresponds to the
name of a route condition. See [Mojolicious route
conditions](https://metacpan.org/pod/Mojolicious::Routes#conditions).

```perl
  # The collection route shortcut below creates the following routes, and maps
  # them to controllers of the camelized route's name.
  #
  # Pattern           Methods   Name                        Class::Method Name
  # -------           -------   ----                        ------------------
  # /accounts         *         accounts
  #   +/              GET       "accounts_list"             Accounts::list
  #   +/              POST      "accounts_create"           Accounts::create
  #   +/:accounts_id  *         "accounts"
  #     +/            *         "accounts_resource_lookup"  Accounts::resource_lookup
  #       +/          DELETE    "accounts_delete"           Accounts::delete
  #       +/          GET       "accounts_read"             Accounts::read
  #       +/          PATCH     "accounts_patch"            Accounts::patch
  #       +/          PUT       "accounts_update"           Accounts::update

  # expects the element id (:accounts_id) for this collection to be a uuid
  my $route = $r->collection('accounts', over => 'uuid');
```

[Mojolicious::Plugin::Restify](https://metacpan.org/release/Mojolicious-Plugin-Restify)
tries not to make too many assumptions, but the author's recent experience
writing a REST-based API using
[Mojolicious](https://metacpan.org/release/Mojolicious) has helped shaped this
plugin, and might unwittingly express some of his bias.
