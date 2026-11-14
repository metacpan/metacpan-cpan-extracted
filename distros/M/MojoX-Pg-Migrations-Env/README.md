# MojoX::Pg::Migrations::Env

Mojo::Pg migrations that replace environment placeholders in their sql.

A drop-in replacement for
[Mojo::Pg::Migrations](https://metacpan.org/pod/Mojo::Pg::Migrations). It is a
subclass that loads, selects and applies migrations exactly like its parent,
with one difference: placeholders in the migration sql are replaced with values
from the environment when the sql is produced. That lets migrations refer to
things that differ between environments, for example the name of a role to
grant to.

The module is sponsored by [Fibia](https://fibia.dk).

```sql
-- 3 up
grant select on invoices to ${APP_READONLY_ROLE:-readonly};
-- 3 down
revoke select on invoices from ${APP_READONLY_ROLE:-readonly};
```

- `${NAME}` is replaced with the value of `NAME`, and fails when it is unset
  or empty.
- `${NAME:-fallback}` uses the fallback instead.
- `$${NAME}` is left as the literal `${NAME}`.

Nothing else is touched, so `$1` and dollar quoted function bodies are safe,
and migrations without placeholders produce the same sql as they do with
`Mojo::Pg::Migrations`.

```perl
use Mojo::Pg;
use MojoX::Pg::Migrations::Env;

my $pg = Mojo::Pg->new('postgresql://app@/app');
$pg->migrations(MojoX::Pg::Migrations::Env->new(pg => $pg, name => 'app'));
$pg->migrations->from_file('db/migrations.sql')->migrate;
```

All sql between two versions is produced before any of it runs, so a missing
variable aborts `migrate` with nothing applied. See the module documentation
for `env`, `placeholders` and `resolve`, which tell what a migration needs and
where each value comes from without running it.

## Development procedure

- Create a branch
- Add a change fragment for each change you make using `changie new`
- Add your feature, and create a pull request
- Have your feature reviewed by your peers
- Merge to main

### Perl toolchain

We use `ExtUtils::MakeMaker::CPANfile` to handle the installation of
`MojoX::Pg::Migrations::Env`.

`ExtUtils::MakeMaker` creates a Makefile that can build and install
`MojoX::Pg::Migrations::Env` just like any other perl module on
[CPAN](https://metacpan.org/).

> [!TIP]
> Run `mise run prepare` to build the code, create the `Makefile`
> and update the `MANIFEST`.

### Tests

`mise run test` runs the tests. The ones that migrate a database are skipped
unless `TEST_ONLINE` holds a database url with a `search_path`, which
`mise.toml` sets for a local PostgreSQL. The tests create and drop the schema
named in `search_path`.

### External dependencies

If you have any external dependencies, add them to the `cpanfile` and install
them using `mise run install:dependencies`

## Release procedure

- Check out `main`
- Run `release:preview` to see a preview of the changelog, and what the next
  version will be.
- Run `release:create` to create the actual release, this will do the following
  - Update the module version in `Env.pm`
  - Run `changie` to create the changelog
  - Tag the code with the new version number
- If you are satisfied with the release, push `main` and the tag to GitHub
  together, where a workflow tests the code, uploads the distribution to
  [PAUSE](https://pause.perl.org/) and creates a GitHub release with the
  changelog of the version. The workflow needs the repository secrets
  `PAUSE_USER` and `PAUSE_PASSWORD`, and only releases tags that are on `main`.

  ```sh
  git push --atomic --follow-tags origin main
  ```

> [!NOTE]
> If you want to override the next version, you can pass
> `--next major` to `mise run release:create` like so:
>
> ```sh
> mise run release:create --next major
> ```
>
> Any version identifier accepted by `changie next` can be used.
> (`major`, `minor`, `patch` and `auto` which is default)
