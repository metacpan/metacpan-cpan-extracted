# NAME

pplquery

OpenSearch::PPLQuery

# SYNOPSIS

    # Run a query saved in a file
    pplquery query.ppl

    # Run a query from standard input
    echo 'source=logs | head 10' | pplquery -

    # Pick an output format
    pplquery --format csv query.ppl > results.csv
    pplquery --format json query.ppl | jq .

    # Use a named connection from the connection file
    pplquery --connection staging query.ppl

    # Point at a cluster directly
    pplquery --url https://search.example.com --user reader query.ppl

    # See which connections are configured
    pplquery --list-connections

# DESCRIPTION

`pplquery` reads an OpenSearch Pipe Processing Language (PPL) query from a file or standard input, and prints the result as a table, as JSON, or as CSV. Its companion ["VS CODE EXTENSION"](#vs-code-extension) transforms your IDE into a PPL Query Studio.

# INSTALLATION

## Step 1: Install Perl and a compiler

**Debian, Ubuntu, and derivatives**

    sudo apt install perl cpanminus build-essential libssl-dev zlib1g-dev

**Fedora, RHEL, and derivatives**

    sudo dnf install perl perl-App-cpanminus gcc openssl-devel zlib-devel

**macOS**

    brew install perl cpanminus openssl

**Windows**

Install Strawberry Perl from [https://strawberryperl.com](https://strawberryperl.com), which bundles a compiler and `cpanm`. Run the commands below from a Strawberry Perl shell.

**Put it on your path**

If you installed to an alternate location you may need to locate and put pplquery into your path.

# RUNNING A QUERY

`pplquery` executes a query from a file or standard input:

    pplquery errors-by-host.ppl
    echo 'source=logs | stats count() by host' | pplquery -

Query files are UTF-8 text. The specification does not allow for comments, but it is hugely convenient for development to have them. pplquery removes lines beginning with '#' before submitting the query.

    # Failed requests in the last hour, busiest hosts first.
    source=access_logs
    | where status >= 500
    | stats count() as failures by host
    | sort - failures
    | head 20

Only whole-line comments are recognised; a `#` partway through a line is sent as part of the query. A query that is empty, or nothing but comments, is an error.

# OPTIONS

- **--config** _FILE_

    Connection configuration file to read. Defaults to `PPLQUERY_CONFIG`, then to the location in ["Where the file goes"](#where-the-file-goes).

- **--connection** _NAME_

    Use the named connection _NAME_. Defaults to `PPLQUERY_CONNECTION`, then to the file's declared default. Cannot be combined with **--url**, **--user**, **--ca-file**, or **--insecure**.

- **--list-connections**

    List the configured connections and exit, marking the default with `*`. Accepts **--format json**; `csv` is not supported. Takes no query file, and cannot be combined with connection or password options.

- **--url** _URL_

    OpenSearch base URL, such as `https://search.example.com`. Defaults to `OPENSEARCH_URL`, then to `http://127.0.0.1:9200`. It must be a base URL: `http` or `https`, a host, no path, and no embedded credentials, query string, or fragment.

- **--user** _USER_

    Basic-authentication username. Defaults to `OPENSEARCH_USERNAME`. Requires an HTTPS URL. See ["PASSWORDS"](#passwords) for the password.

- **--password-file** _FILE_

    Read the password from a UTF-8 file, one trailing line ending removed. Overrides the password source of a selected connection. Defaults to `PPLQUERY_PASSWORD_FILE`.

- **--ca-file** _FILE_

    Certificate authority file used to verify the server's certificate, for a cluster with a private or internal CA. Requires HTTPS, and cannot be combined with **--insecure**.

- **--insecure**

    Disable certificate and hostname verification. Requires HTTPS. This forfeits the protection HTTPS gives against an impersonated server, so prefer **--ca-file** wherever the certificate can be verified.

- **--format** _FORMAT_

    Output format: `table` (default), `json`, or `csv`. See ["OUTPUT FORMATS"](#output-formats).

- **--max-width** _N_

    Truncate table cells to _N_ characters, marking shortened values with an ellipsis. `0`, the default, means no limit. Affects `table` only.

- **--timeout** _SECONDS_

    HTTP timeout. Defaults to `60`, or to a selected connection's `timeoutSeconds`, and overrides either. Must be greater than zero.

- **--help**

    Print a usage summary and exit successfully.

# OUTPUT FORMATS

The default output is a table, the maximum cell width can be controlled with the --max-width switch, output may also be in either CSV or JSON, json output gets the full error messages.

# CONNECTING TO A CLUSTER

**Direct options** name the endpoint on the command line or in the environment: **--url**, **--user**, **--ca-file**, and **--insecure**, backed by `OPENSEARCH_URL`, for authenticated clusters `OPENSEARCH_USERNAME` `OPENSEARCH_PASSWORD` are required . This suits a single cluster, and is the shortest path when trying the tool for the first time.

**Named connections** store each cluster's endpoint, username, TLS policy, and password source together under a name, selected with **--connection**.

When using **--connection** any with other direct parameters is an error, and environment variables other than `OPENSEARCH_PASSWORD` are ignored.

## Which cluster is chosen

When several sources could apply, `pplquery` resolves them in this order:

1. **--connection** _NAME_, if given.
2. `PPLQUERY_CONNECTION`, if set and no direct option was given.
3. The configuration file's default connection, if the file was named by **--config** or `PPLQUERY_CONFIG`, or if it exists and `OPENSEARCH_URL` is not set.
4. Direct configuration: `OPENSEARCH_URL` or `http://127.0.0.1:9200`, with any direct options applied on top.

The third rule is what keeps `OPENSEARCH_URL` working as it always did: setting it outranks a configuration file's default, so adding a connection file does not change an existing environment-based setup. Naming a file explicitly overrides that.

# NAMED CONNECTIONS

A named connection records everything needed to reach one cluster — URL, username, TLS policy, timeout, and where to find its password — under a short name, turning this:

    pplquery --url https://search-staging.example.com --user ppl-reader \
             --ca-file ~/certificates/staging-ca.pem query.ppl

into this:

    pplquery --connection staging query.ppl

Connections live in a JSON file. **There is no default file and no command that creates one** — if you have never made one, you do not have one, and `pplquery` uses direct configuration instead. Creating the file is the whole of the setup.

## Where the file goes

- Unix and macOS: `$XDG_CONFIG_HOME/pplquery/connections.json`, or `~/.config/pplquery/connections.json` when `XDG_CONFIG_HOME` is not set
- Windows: `%APPDATA%\pplquery\connections.json`

**--config** _FILE_ or `PPLQUERY_CONFIG` reads a different file, which suits a connection file checked into a project alongside the queries and certificates it belongs with.

## Creating your first connection

Make the directory and the file:

    mkdir -p ~/.config/pplquery
    install -m 600 /dev/null ~/.config/pplquery/connections.json

Mode `600` makes it readable only by you. It holds no passwords, but it does describe your clusters and usernames.

Put this in it — the smallest file that does something useful:

    {
      "default": "local",
      "connections": {
        "local": {
          "url": "http://127.0.0.1:9200",
          "authentication": {"type": "none"} } }
    }

`connections` holds one entry per cluster, keyed by the name you will use with **--connection**.

    pplquery --list-connections

    * local       http://127.0.0.1:9200   none

The `*` marks the default. Adding **--format json** prints the same thing machine-readably, including each connection's password source and TLS settings.

## Adding a cluster that needs a password

A real cluster usually wants credentials. Add a second entry beside `local` in `connections`:

    "staging": {
      "url": "https://search-staging.example.com",
      "authentication": {"type": "basic", "username": "ppl-reader",
                         "passwordEnvironment": "STAGING_PPL_PASSWORD"} }

`"type": "basic"` turns on HTTP Basic authentication and requires a `username` and an `https` URL. `passwordEnvironment` says _where the password comes from_, not what it is; the password itself never appears in this file. Before querying `staging`, put it in that variable:

    read -rs STAGING_PPL_PASSWORD && export STAGING_PPL_PASSWORD
    pplquery --connection staging query.ppl

Swap `passwordEnvironment` for `passwordFile` to read from a file instead, which suits unattended jobs. A connection may name one of these, never both; with neither, the password falls back to `OPENSEARCH_PASSWORD`. See ["PASSWORDS"](#passwords).

## Adding a private certificate authority

An internal cluster's certificate is often signed by a CA your system does not trust, which shows up as `certificate verify failed`. Name the CA certificate rather than switching verification off, by adding to the `staging` entry:

    "tls": {"verify": true, "caFile": "certificates/staging-ca.pem"}

`caFile` is relative to the directory holding the configuration file, so `~/.config/pplquery/certificates/staging-ca.pem` is what gets read; `passwordFile` resolves the same way. That is deliberate: a connection file, its certificates, and its password files can be moved, backed up, or checked into a project as one unit.

## Property reference

At the top level, `connections` is required and `default` is optional. `default` is a sibling of `connections`, not a member of it — putting it inside produces the confusing complaint that a connection named `default` is not an object.

Connection names must start with a letter or digit, and may then contain letters, digits, dots, underscores, and hyphens.

Each connection accepts exactly these properties:

- `url`

    **Required.** The cluster's base URL: `http` or `https`, a host, optionally a port. No path, credentials, query string, or fragment — `https://search.example.com:9200` is fine, `https://search.example.com/_plugins/_ppl` is not, because the endpoint path is appended for you.

- `authentication`

    **Required**, even when there is none to do — write `{"type": "none"}`. `type` is `"none"` or `"basic"`.

    `"basic"` also requires `username` (ASCII only) and an `https` URL, and accepts at most one of `passwordEnvironment` (the name of an environment variable) or `passwordFile` (a path). Neither `username` nor a password source may appear under `"none"`.

- `tls`

    _Optional_, and permitted only on `https` URLs — present but empty (`{}`) still counts as present, and is rejected on `http`.

    `verify` is a JSON boolean, defaulting to true; `false` disables certificate and hostname checking and is incompatible with `caFile`. `caFile` is a path to a certificate authority file.

- `timeoutSeconds`

    _Optional_ positive integer, defaulting to `60`. It must be a JSON integer: `60` is accepted, `"60"` and `60.0` are not.

Unknown properties are rejected rather than ignored, at every level. A setting quietly discarded because of a typo could leave you believing TLS verification or a password source had been applied when it had not.

## Several connections, one cluster

Nothing requires connection names to map one-to-one onto clusters. Multiple entries may share a URL with different usernames and password sources:

    "logs-reader":  {"url": "https://search.example.com",
                     "authentication": {"type": "basic", "username": "logs-ro",
                                        "passwordEnvironment": "LOGS_RO_PASSWORD"}},
    "metrics-admin": {"url": "https://search.example.com",
                      "authentication": {"type": "basic", "username": "metrics-rw",
                                         "passwordEnvironment": "METRICS_RW_PASSWORD"}}

This is how to work with a cluster whose index-level security grants different principals access to different indices: choose the identity by name at the point of use, rather than by remembering to change an environment variable.

## When the file is wrong

The whole file is parsed and validated before any network call, so a mistake is reported as a specific complaint rather than a puzzling failure later. Errors name the connection and the property:

    Connection 'staging' contains unknown property 'timeout'
    Connection 'staging' basic authentication requires an https URL
    Connection 'staging' url must be a base URL without a path

Three situations are not errors at all:

- **The file does not exist.** At the default location it is skipped silently and direct configuration applies. Only a file named by **--config** or `PPLQUERY_CONFIG` must exist.
- **The file has no `default`.** Valid, but every run must then select a connection with **--connection** or `PPLQUERY_CONNECTION`; one that does not is told `has no default connection; use --connection`.
- **`OPENSEARCH_URL` is set.** It outranks the configuration file, unless the file was named explicitly; see ["Which cluster is chosen"](#which-cluster-is-chosen).

# PASSWORDS

A password is never accepted as a command-line argument, because arguments are visible to every other process on the machine and are recorded in shell history. It is never read from the connection file either; that file describes where the password comes from, not what it is. Basic authentication is refused over plain HTTP, so credentials are never sent in the clear.

For a connection with `"type": "basic"`, the password is found in this order:

1. The file named by **--password-file** or `PPLQUERY_PASSWORD_FILE`. This per-invocation override beats the connection's own setting.
2. The environment variable named by the connection's `passwordEnvironment`. If it is unset the run fails rather than falling back — a connection that names its own variable is taken at its word.
3. The file named by the connection's `passwordFile`.
4. `OPENSEARCH_PASSWORD`.

Without a named connection, only steps 1 and 4 apply.

Password files are UTF-8, and one trailing line ending is removed. Restrict their permissions:

    install -m 600 /dev/null ~/.config/pplquery/staging.password
    printf '%s' 'the-password' > ~/.config/pplquery/staging.password

# ENVIRONMENT

The `PPLQUERY_*` variables stand in for the corresponding options: `PPLQUERY_CONFIG` for **--config**, `PPLQUERY_CONNECTION` for **--connection**, `PPLQUERY_PASSWORD_FILE` for **--password-file**.

The `OPENSEARCH_*` variables configure one cluster directly, and apply whenever no named connection does: `OPENSEARCH_URL` (default `http://127.0.0.1:9200`), `OPENSEARCH_USERNAME`, and `OPENSEARCH_PASSWORD`. For a single local cluster these three are the entire setup — no configuration file is needed, and `OPENSEARCH_URL` alone is enough for an unauthenticated one. See ["Which cluster is chosen"](#which-cluster-is-chosen) and ["PASSWORDS"](#passwords) for how they rank against a connection file.

# EXIT STATUS

`pplquery` exits `0` when the query succeeds and `1` otherwise — a rejected query, an authentication or TLS failure, an unreachable cluster, a malformed connection file, or invalid options.

Errors go to standard error prefixed with `pplquery:`, so they stay out of piped or redirected results. **--format json** is the exception: an error response from OpenSearch is printed to standard output as JSON, with exit status still `1`, keeping the cluster's full error available to scripts.

# VS CODE EXTENSION

An extension for Visual Studio Code and compatible editors runs `.ppl` files from the editor, providing syntax highlighting, snippets, field-name completion, and a results panel. It executes queries by invoking the `pplquery` command described here.

Install `pplquery` first. The extension expects it on `PATH`; if it is elsewhere, set `pplquery.path` to the executable's full path.

## From the Visual Studio Marketplace

Open the Extensions view, search for **OpenSearch PPL Query**, and install the entry published by **brainbuz**. From a shell:

    code --install-extension brainbuz.pplquery

## From the Codeberg repository

Editors that do not use the Visual Studio Marketplace can install the packaged extension directly. Download the `.vsix` from [https://codeberg.org/brainbuz/pplquery/releases](https://codeberg.org/brainbuz/pplquery/releases):

    code --install-extension pplquery-1.0.0.vsix

Substitute the version you downloaded, and your editor's own command for `code`. The same file installs from the Extensions view through the `...` menu, **Install from VSIX**. To build it from a checkout, run `vsce package` in the `vscode` directory.

## Settings

The extension does not create or modify connection files. Set `pplquery.config` and `pplquery.connection` to use a named connection, or leave them unset and let the CLI's own configuration apply. Passwords are never stored in editor settings: when direct Basic authentication needs one, the extension prompts for it and keeps it in memory for the session only.

# TROUBLESHOOTING

- `Basic authentication requires an https URL`

    A username was supplied for an `http://` endpoint. Use the cluster's HTTPS URL.

- `certificate verify failed`

    The cluster's certificate was not signed by a certificate authority your system trusts, which is usual for an internal cluster. Point **--ca-file**, or the connection's `caFile`, at the issuing CA certificate. **--insecure** also silences it, but disables the check that detects an impersonated server.

- `OpenSearch URL must be a base URL without a path`

    The URL includes a path, such as a trailing `/_plugins/_ppl`. Give only the scheme, host, and port.

- `Connection configuration ... contains unknown property`

    A property name is misspelled, or belongs at a different level of the file. Compare it against ["Property reference"](#property-reference).

# CLOUD AND MANAGED OPENSEARCH

Many Organizations that use Amazon OpenSearch Service likely require IAM, AWS Signature Version 4 request signing is not currently implemented. Other providers have their own schemes — API keys, bearer tokens, mutual TLS — and none are implemented either.

If you use OpenSearch through AWS or another managed provider and would like `pplquery` to work there, please open a pull request or an issue at [https://codeberg.org/brainbuz/pplquery](https://codeberg.org/brainbuz/pplquery). Provider implementations should include mock tests that were developed from live tests against the target environment.

# SEE ALSO

OpenSearch PPL reference: [https://opensearch.org/docs/latest/search-plugins/sql/ppl/index/](https://opensearch.org/docs/latest/search-plugins/sql/ppl/index/)

Project repository and issue tracker: [https://codeberg.org/brainbuz/pplquery](https://codeberg.org/brainbuz/pplquery)

This distribution provides a client for one purpose: running PPL queries. Here are some modules that aim to be more complete:

- [OpenSearch](https://metacpan.org/pod/OpenSearch) — an unofficial client built on Moo and Mojo::UserAgent, supporting synchronous and asynchronous requests across a subset of the API.
- [OpenSearch::Client](https://metacpan.org/pod/OpenSearch%3A%3AClient) — an unofficial client derived from [Search::Elasticsearch](https://metacpan.org/pod/Search%3A%3AElasticsearch), tracking OpenSearch's divergence from it.

# AUTHOR

John Karr <brainbuz@brainbuz.org>

# LICENSE

Copyright 2026 John Karr.

This is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 or later.
