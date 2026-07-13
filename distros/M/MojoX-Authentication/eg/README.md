Example for MojoX::Authentication

This example works under the assumption that it will run on port 3000 and
it will be called via browser at address http://127.0.0.1:3000

Setup with:

```
./kickstart-db.sh
carton
```

See [https://etoobusy.polettix.it/2020/01/04/installing-perl-modules/](https://etoobusy.polettix.it/2020/01/04/installing-perl-modules/)
to figure out what `carton` is and how to install from the `cpanfile`
dependencies file in case you lack it.

Run with:

```
./app.pl daemon
```

The example supports the following credentials:

- User `foo` password `123`, local hardcoded
- User `bar` password `456`, local hardcoded
- User 'baz` password `123`, local database `testdb.sqlite`
- Anything coming from the SAML2 Identity Provider when you click on link
  `Login (SAML2)`.
