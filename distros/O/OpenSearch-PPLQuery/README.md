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

    # Point at a cluster directly
    pplquery --url https://search.example.com query.ppl

    # Use Basic authentication without putting the password in an argument
    read -rs PPLQUERY_PASSWORD && export PPLQUERY_PASSWORD
    pplquery --url https://search.example.com \
      --user reader query.ppl

    # Or keep reusable connection metadata in the query itself
    // pplquery
    // url: https://search.example.com
    // user: reader
    // password-environment: PPLQUERY_READER_PASSWORD
    // timeout: 30

    source = logs | head 10

    # Or select one reusable standalone connection header
    pplquery --connection-file connections/production.pplconn query.ppl

# DESCRIPTION

`pplquery` reads an OpenSearch Piped Processing Language (PPL) query from a file or standard input, and prints the result as a table, as JSON, or as CSV. Its companion ["VS CODE EXTENSION"](#vs-code-extension) transforms your IDE into a PPL Query Studio.

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

Query files are UTF-8 text. A connection header is optional. Without one, the complete decoded query is submitted unchanged. With one, `pplquery` removes the header and its separator before submission; see ["CONNECTION HEADERS"](#connection-headers). Other PPL comments, including `//` to the end of a line and `/* ... */` blocks, remain part of the query sent to OpenSearch.

    // Failed requests in the last hour, busiest hosts first.
    source=access_logs
    | where status >= 500        // server errors only
    | stats count() as failures by host
    | sort - failures
    | where @timestamp >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
    | head 20

# OPTIONS

- **--connection-file** (**-c**) _FILE_

    Read connection metadata from one strict `// pplquery` header in a UTF-8 file. The file must contain only the header and optional trailing whitespace; unlike a query header, it does not require a blank separator at EOF. Its fields override approved environment values and defaults but remain below explicit command-line connection options. This is not the removed named JSON configuration interface; see ["CONNECTION FILES"](#connection-files).

- **--url** (**-u**) _URL_

    OpenSearch base URL, such as `https://search.example.com`. Overrides the selected connection-file or query-header `url` and `PPLQUERY_URL`; the final default is `http://127.0.0.1:9200`. It must be an ASCII `http` or `https` base URL with a host and no credentials, query string, fragment, or path other than `/`.

- **--user** (**-U**) _USER_

    Basic-authentication username. Overrides the selected connection-file or query-header `user` and `PPLQUERY_USER`. The username must be ASCII and must be paired with exactly one selected password source. Basic authentication requires HTTPS. See ["AUTHENTICATION AND PASSWORDS"](#authentication-and-passwords).

- **--password-file** (**-p**) _FILE_

    Read the Basic-authentication password from a UTF-8 file. This replaces both header password reference fields and both environment password sources. A relative command-line path resolves against the process current directory. See ["AUTHENTICATION AND PASSWORDS"](#authentication-and-passwords).

- **--ca-file** _FILE_

    Certificate authority file used to verify the server's certificate, for a cluster with a private or internal CA. Overrides the selected connection-file or query-header `ca-file` and `PPLQUERY_CA_FILE`. A relative command-line path resolves against the process current directory. Requires HTTPS and cannot be combined with **--insecure** or a selected `tls-verify: false` value.

- **--insecure**

    Disable certificate and hostname verification, overriding the selected connection-file or query-header `tls-verify` and `PPLQUERY_TLS_VERIFY`. Requires HTTPS. This forfeits the protection HTTPS gives against an impersonated server, so prefer **--ca-file** wherever the certificate can be verified.

- **--format** (**-f**) _FORMAT_

    Output format: `table` (default), `json`, or `csv`. See ["OUTPUT FORMATS"](#output-formats).

- **--max-width** (**-w**) _N_

    Truncate table cells to _N_ terminal columns, marking shortened values with an ellipsis. A value is cut only between characters, so an accent or other combining mark is never separated from the character it belongs to. `0`, the default, means no limit. Affects `table` only. Internally pplquery counts columns, but multi-character sequences may not always be counted correctly.

- **--timeout** (**-t**) _SECONDS_

    Positive HTTP timeout in seconds, up to `86400`. Overrides the selected connection-file or query-header `timeout` and `PPLQUERY_TIMEOUT`; the final default is `60`.

- **--help**

    Print a usage summary and exit successfully.

# OUTPUT FORMATS

The default output is a table. The maximum table-cell width can be controlled with **--max-width**. Output may also be CSV or JSON; JSON output preserves full OpenSearch error responses.

# CONNECTING TO A CLUSTER

`pplquery` combines explicit command-line connection options, either the file selected by **--connection-file** or an optional header in the query, environment variables, and built-in defaults. A query without either header source uses command-line options, environment variables, and defaults; with no connection settings at all it connects anonymously to `http://127.0.0.1:9200`, verifies TLS when HTTPS is selected, and uses a 60-second timeout.

# CONNECTION HEADERS

A query may begin with connection metadata in PPL line comments. The complete header, including the required separator line, is stripped before the query is submitted.

    // pplquery
    // url: https://cluster.example.com:9200
    // user: analyst
    // password-environment: PPLQUERY_ANALYST_PASSWORD
    // ca-file: certificates/internal-ca.pem
    // tls-verify: true
    // timeout: 60

    source = logs
    | where status >= 500

## Exact syntax and termination

The sentinel must be exactly `// pplquery` on line 1, optionally followed by spaces or tabs, and then an LF or CRLF line ending. Leading whitespace is forbidden. Header fields immediately follow as contiguous lines in the exact form `// key: value`: there is exactly one space between `//` and the key, the key starts with a lowercase ASCII letter and continues with only lowercase ASCII letters, digits, or hyphens, and the colon immediately follows the case-sensitive key. Spaces and tabs after the colon and at the end of the value are trimmed; internal whitespace is preserved.

A line containing only spaces or tabs terminates the header and is required even when the header contains no fields. Every line between the sentinel and this separator must be a field line, so an ordinary comment or query text there is malformed. LF and CRLF are accepted; bare CR is not. An exact sentinel with leading indentation, after line 1, or repeated later in the submitted query is an error rather than ordinary query text. Text such as `// pplquery-specific` is not a sentinel.

The header is optional. This fieldless header is valid and uses environment settings and defaults:

    // pplquery

    source = logs

## Supported fields

Only these fields are supported:

- `url`

    The OpenSearch base URL. It has the same validation as **--url**: ASCII `http` or `https`, a host, no credentials, query, fragment, or non-root path.

- `user`

    The ASCII Basic-authentication username. Authentication is inferred after all fields are merged; see ["AUTHENTICATION AND PASSWORDS"](#authentication-and-passwords).

- `password-environment`

    The name of the environment variable from which to read the password. It must match `PPLQUERY_[A-Z][A-Z0-9_]*`. This is a reference, not a password value.

- `password-file`

    The path of a UTF-8 password file holding the password on a single line. It is mutually exclusive with `password-environment`.

- `ca-file`

    The CA certificate used for HTTPS verification. It requires an HTTPS URL and cannot be combined with `tls-verify: false`. A query header may only supply it for a URL that same header selects; see ["Header transport trust"](#header-transport-trust).

- `tls-verify`

    Whether to verify the HTTPS certificate and hostname. The value must be exactly lowercase `true` or `false`. A query header may only turn verification off for a URL that same header selects; see ["Header transport trust"](#header-transport-trust).

- `timeout`

    The HTTP timeout in seconds. The value must be a canonical positive integer: digits beginning with `1` through `9`, with no sign, leading zero, decimal point, or whitespace after header trimming.

Unknown fields, including `password`, are rejected. Duplicate, malformed, and empty fields are rejected. Header syntax, individual values, and relationships between header fields are validated even if a higher-precedence command-line option will replace them. An overridden password reference is checked for valid syntax but its environment variable or file is not resolved.

## Paths and submitted text

Relative `password-file` and `ca-file` paths in a query header resolve against that query file's directory. In a query header read from standard input, they resolve against the process current directory. Relative paths in a file selected by **--connection-file** resolve against the selected file's directory. Absolute paths remain absolute. Relative paths supplied by command-line options or environment variables resolve against the process current directory.

After decoding the input as UTF-8, `pplquery` removes the complete header and separator and submits the remainder character-for-character. Header metadata never reaches OpenSearch as query text. A header-only input or a remainder containing only whitespace is rejected as an empty query. Without an exact sentinel, the decoded query is submitted unchanged after checks for a misplaced sentinel.

# CONNECTION FILES

**--connection-file** selects one UTF-8 file containing exactly one header under the same strict sentinel, field, value, and relationship rules described in ["CONNECTION HEADERS"](#connection-headers). Standalone connection files conventionally use the `.pplconn` filename extension; the CLI accepts any explicitly supplied filename. The sentinel is mandatory. Trailing ASCII spaces, tabs, and line endings are ignored, so EOF terminates the external header without requiring a blank separator line; if a separator is present, only whitespace may follow it. An unreadable file, invalid UTF-8, absent sentinel, malformed or invalid header, or non-whitespace body is rejected before an OpenSearch client is created.

For example, `connections/production.pplconn` can contain:

    // pplquery
    // url: https://search.example.com
    // user: reader
    // password-file: secrets/reader.password
    // ca-file: certificates/internal-ca.pem
    // timeout: 30

Both relative paths resolve from the `connections` directory, regardless of the query file's location or the process current directory.

When **--connection-file** is supplied, any connection header-like text in the query is non-authoritative and is not strictly validated. If the query begins with the exact sentinel line and a blank or horizontal-whitespace separator line occurs later, `pplquery` strips through the first such separator without examining the intervening lines. If that complete anchored shape is absent, including an incomplete, late, or indented header-like comment, the query is passed to OpenSearch unchanged. Query emptiness is checked after this stripping.

This deliberately small behavior lets an operator override a query's metadata without allowing malformed query metadata to block the selected connection. The external file itself remains fully strict.

# PRECEDENCE

Connection values normally merge field by field in this order: explicit command-line option, selected connection-file or query-header field, approved environment variable, then default. **--connection-file** makes its header the only metadata tier and query-header fields are ignored as connection inputs. Supplying one higher-precedence field does not replace unrelated lower-precedence fields. For example, a connection-file `timeout` may be combined with `PPLQUERY_URL`, while **--user** may be combined with a selected header password source.

- URL: **--url**, selected `url`, `PPLQUERY_URL`, then `http://127.0.0.1:9200`
- User: **--user**, selected `user`, then `PPLQUERY_USER`
- Password source: **--password-file**, one selected header password reference, then `PPLQUERY_PASSWORD` or `PPLQUERY_PASSWORD_FILE`
- CA file: **--ca-file**, selected `ca-file`, then `PPLQUERY_CA_FILE`, restricted for query headers by ["Header transport trust"](#header-transport-trust)
- TLS verification: **--insecure**, selected `tls-verify`, `PPLQUERY_TLS_VERIFY`, then verification enabled, restricted for query headers by ["Header transport trust"](#header-transport-trust)
- Timeout: **--timeout**, selected `timeout`, `PPLQUERY_TIMEOUT`, then `60`

The password alternatives form one mutually exclusive semantic field. **--password-file** replaces either selected header reference and both environment sources. A selected query-header or connection-file `password-environment` or `password-file` replaces both environment sources. Otherwise `PPLQUERY_PASSWORD` and `PPLQUERY_PASSWORD_FILE` conflict if both are present. Lower-precedence environment values are not validated or resolved when the corresponding field has been replaced.

## Header URL authentication isolation

There is one security-specific exception to ordinary field merging. When the selected URL comes from the query header because neither **--url** nor **--connection-file** was supplied, environment authentication is excluded as a unit: `PPLQUERY_USER`, `PPLQUERY_PASSWORD`, and `PPLQUERY_PASSWORD_FILE` are not inherited for that endpoint. The query header may select anonymous access, or it must provide enough explicit CLI/header values to pair a username with a password source. A one-sided query-header user or password reference does not fall back to environment authentication.

If **--url** replaces the query-header URL, environment authentication may merge because the query no longer controls the selected endpoint. A connection-file URL may also merge with environment authentication because **--connection-file** was explicitly selected by the operator. Timeout continues to follow normal field-by-field precedence; CA and TLS verification are subject to the separate restriction below.

## Header transport trust

A query header decides how the connection is verified only for a URL that same header selects. If the URL comes from **--url** or from `PPLQUERY_URL`, a query header carrying `ca-file` or `tls-verify: false` is refused with an error rather than applied, because the operator chose that endpoint and the query would otherwise be weakening the protection guarding it. Naming a CA is a restriction in form only: a CA the query chose accepts a server the operator's trust store would have rejected, exactly as skipping verification does.

`tls-verify: true` is never refused, because it asks for the verification that is already the default and weakens nothing. A header field that a command-line option replaces is not refused either, since the replaced value is never applied. A file selected by **--connection-file** is exempt from the whole restriction: the operator chose that file explicitly, so its `ca-file` and `tls-verify` apply to a URL from any source.

# AUTHENTICATION AND PASSWORDS

There is no authentication-type option or header field. Basic authentication is inferred only when the merged connection contains both a user and one selected password source. Neither means anonymous access; either one alone is an error. Basic authentication is refused over plain HTTP, so credentials are not sent without HTTPS. Usernames and resolved passwords must be ASCII.

Passwords are not accepted as command-line values or raw header fields. Command arguments are visible to other processes and may be recorded in shell history, while query files are commonly shared. Use **--password-file**, `PPLQUERY_PASSWORD`, `PPLQUERY_PASSWORD_FILE`, or a header password reference.

A selected `password-environment` must name a nonempty variable matching `PPLQUERY_[A-Z][A-Z0-9_]*`. The named variable must be present and nonempty. It does not fall back to `PPLQUERY_PASSWORD`, and no variable outside the `PPLQUERY_` namespace can be named.

A selected password file is decoded as UTF-8 and holds the password on a single line. Trailing LF and CRLF line endings are removed, however many the file ends with, so a file saved with a trailing blank line still yields the password the author intended. Trailing spaces are kept, because a password may legitimately end in one. The result must be nonempty and must not contain a line break or other control character: a file holding more than one line is a mistake rather than a multi-line password, and is rejected instead of producing an authentication failure whose cause is invisible. Restrict password-file permissions:

    install -m 600 /dev/null ~/.config/pplquery/reader.password
    read -rs password
    printf '%s' "$password" > ~/.config/pplquery/reader.password && unset password
    PPLQUERY_PASSWORD_FILE=$HOME/.config/pplquery/reader.password \
      PPLQUERY_USER=reader PPLQUERY_URL=https://search.example.com \
      pplquery query.ppl

## Query-file trust and secret disclosure

A query that controls `url` and names a `PPLQUERY_*` password variable explicitly authorizes sending that secret to that endpoint. Treat query files with connection headers as security-sensitive input: inspect an untrusted or newly downloaded query before running it. Namespace restriction, explicit username/password pairing, HTTPS enforcement, header-URL isolation, and the transport-trust restriction described in ["Header transport trust"](#header-transport-trust) prevent accidental inheritance, unrelated-environment lookup, and silent weakening of a connection the query did not choose, but they do not make a deliberately named secret safe to disclose to an untrusted endpoint. `pplquery` does not prompt or try compatibility fallbacks.

# ENVIRONMENT

All supported connection environment variables use the `PPLQUERY_` namespace. Every present selected value must be nonempty. Boolean and integer values are strict and are not trimmed.

- `PPLQUERY_URL`

    OpenSearch base URL. Default: `http://127.0.0.1:9200`.

- `PPLQUERY_USER`

    ASCII Basic-authentication username. It must be paired with a selected password source and is excluded when a query-header URL is selected, but may merge with an operator-selected connection-file URL.

- `PPLQUERY_PASSWORD`

    Direct Basic-authentication password. It conflicts with `PPLQUERY_PASSWORD_FILE`, is excluded when a query-header URL is selected, and is replaced by a CLI or selected header password source.

- `PPLQUERY_PASSWORD_FILE`

    Path to a UTF-8 password file. It conflicts with `PPLQUERY_PASSWORD`, is excluded when a query-header URL is selected, and is replaced by a CLI or selected header password source.

- `PPLQUERY_CA_FILE`

    CA certificate path for HTTPS verification. It cannot be combined with disabled TLS verification.

- `PPLQUERY_TLS_VERIFY`

    Exactly `true` or `false`. Default: `true`.

- `PPLQUERY_TIMEOUT`

    A canonical positive integer with no sign, leading zero, decimal point, or surrounding whitespace. Default: `60`.

# EXIT STATUS

`pplquery` exits `0` when the query succeeds and `1` otherwise: a rejected query, an authentication or TLS failure, an unreachable cluster, a malformed query or external connection header, an empty query, or invalid options.

Errors go to standard error prefixed with `pplquery:`, so they stay out of piped or redirected results. **--format json** is the exception: an error response from OpenSearch is printed to standard output as JSON, with exit status still `1`, keeping the cluster's full error available to scripts.

# VS CODE EXTENSION

An extension for Visual Studio Code and compatible editors runs `.ppl` files from the editor, providing syntax highlighting, snippets, field-name completion, and a results panel. It executes queries by invoking the `pplquery` command described here.

Install `pplquery` first. The extension expects it on `PATH`; if it is elsewhere, set `pplquery.path` to the executable's full path.

With CodeLens enabled, every `.ppl` document has a control row above line 1 containing **Run Query** and **Connection: Header/env**. Click the connection control to open a compact list of the active file, recently selected files, and `*.pplconn` files in the workspace. Choose **Browse...** only when the file is elsewhere. The control displays the selected filename and adds **Clear Connection**. The absolute path and recent list are retained in VS Code workspace state, not user or workspace settings, and the active file is passed to both query execution and field completion as **--connection-file**. The same select and clear actions are available from the Command Palette.

While an external connection file is selected, the CLI strips and ignores a complete leading query header as described in ["CONNECTION FILES"](#connection-files). The extension does not read the external file, so it cannot prompt for a `password-environment` named there; that variable must already exist in the extension environment, or the connection file can use `password-file`. Selecting or clearing a connection file clears cached field names. Run **PPL: Refresh PPL Field Names** after the selected file's contents or an index mapping changes.

## From the Visual Studio Marketplace

Open the Extensions view, search for **OpenSearch PPL Query**, and install the entry published by **brainbuz**. From a shell:

    code --install-extension brainbuz.pplquery

## From the Codeberg repository

Editors that do not use the Visual Studio Marketplace can install the packaged extension directly. Download the `.vsix` from [https://codeberg.org/brainbuz/pplquery/releases](https://codeberg.org/brainbuz/pplquery/releases):

    code --install-extension pplquery-1.0.0.vsix

Substitute the version you downloaded, and your editor's own command for `code`. The same file installs from the Extensions view through the `...` menu, **Install from VSIX**. To build it from a checkout, run `vsce package` in the `vscode` directory.

# TROUBLESHOOTING

Every error names the problem on its first line, echoing the value that was rejected and, for a header field, the line it appeared on. Because a connection field can be set from several places, the following lines list the sources that field accepts rather than reporting which one supplied the value; check the ones you use. Errors are matched below by their opening words.

- `Cannot reach OpenSearch at ...`

    The connection was never established, so the cluster returned nothing and is not necessarily at fault. The cause follows the endpoint: `Connection refused` usually means the wrong port or a cluster that is not running, a hostname failure means the name did not resolve, and `certificate verify failed` is covered separately below. Confirm the URL, then that the cluster is reachable from this host.

- `Basic authentication requires an https URL`

    A username was supplied for an `http://` endpoint. Use the cluster's HTTPS URL.

- `Basic-auth username and password must be set together`

    The merged connection contains only one half of Basic authentication. The message says which half was supplied and lists the sources for the missing one. Supply both, or remove both for anonymous access. When the URL comes from a query header, the message also says that environment authentication was intentionally excluded for that endpoint; see ["Header URL authentication isolation"](#header-url-authentication-isolation).

- `certificate verify failed`

    Reported as part of `Cannot reach OpenSearch`. The cluster's certificate was not signed by a certificate authority your system trusts, which is usual for an internal cluster. Point **--ca-file**, header `ca-file`, or `PPLQUERY_CA_FILE` at the issuing CA certificate. **--insecure** also silences it, but disables the check that detects an impersonated server.

- `A CA file requires an https URL`

    A CA certificate was supplied for an `http://` endpoint, where there is no certificate to verify. The message echoes the URL in force. Either use the cluster's HTTPS URL or drop the CA file.

- `A CA file and disabled TLS verification cannot be used together`

    Both a CA file and `tls-verify: false` or **--insecure** were selected. A CA file already restricts which certificates are accepted, so the two settings contradict each other. Keep whichever you meant.

- `A query header may not choose the CA` / `may not disable TLS verification`

    A query header tried to change how the connection is verified for a URL it did not select; see ["Header transport trust"](#header-transport-trust). Give the header its own `url` field, move the setting to the command line, or select the connection with **--connection-file**.

- `Malformed pplquery header field`

    A header line is not in the required form. The message quotes the line and its number. Every field is written exactly `// key: value`: one space after the slashes, no space before the colon. A line that is an ordinary comment rather than a field is rejected too, because a connection header admits no free text.

- `Password file ... must contain a single line`

    The file holds a line break or control character after its trailing line endings were removed, so it contains more than a password. This is almost always a file saved with extra content rather than a deliberately multi-line password, and is rejected here instead of failing later as an authentication error with no visible cause.

- `Query is empty`

    The input contains no PPL text. The message names the file, or standard input. A connection header and its separator line are metadata and are removed before this check, so a file holding only a header is empty as far as the query is concerned; a header-only file belongs to **--connection-file**.

- `... is not valid UTF-8`

    A query file, connection file, password file, environment variable, or command-line argument contained bytes that are not UTF-8. `pplquery` decodes every input as UTF-8 and never guesses another encoding. Re-save the file as UTF-8.

- `HTTP ... with a body that is not JSON` / `The response ... is not valid JSON`

    Something answered, but not with the JSON the PPL plugin returns. A proxy, load balancer, or sign-in page in front of the cluster is the usual cause, and its status code and the start of its body are shown to help identify it. Confirm the URL addresses OpenSearch directly, and that any gateway in between passes `/_plugins/_ppl` through.

- `OpenSearch URL must be a base URL without a path`

    The URL includes a path, such as a trailing `/_plugins/_ppl`. Give only the scheme, host, and port.

- `The pplquery header requires a blank separator line`

    The query input starts with the exact `// pplquery` sentinel but has no spaces-only or tabs-only separator after its field lines, so the parser read to the end of the input still inside the header. The message names the last line it read, which is usually the first line of the query being consumed as a field. Add the required separator before the PPL query. A standalone file selected by **--connection-file** may instead end after its final field.

- `OpenSearch returned HTTP ...`

    The cluster answered and rejected the request. The cluster's own `reason` leads the message, with its error type in parentheses; for a query mistake that reason names the token it stopped at. Add **--format json** to see the full error document, which is printed to standard output so it can be piped.

- `Unknown pplquery header field`

    The header contains a misspelled or unsupported key. The message quotes the line, its number, and the full list of supported fields; ["Supported fields"](#supported-fields) describes each one. Raw passwords and unapproved extension fields are intentionally rejected.

- `PPLQUERY_PASSWORD and PPLQUERY_PASSWORD_FILE cannot both be set`

    The environment selects two password sources at the same precedence tier. Unset one, or select a single higher-precedence source with **--password-file**, header `password-environment`, or header `password-file`.

# CLOUD AND MANAGED OPENSEARCH

Many Organizations that use Amazon OpenSearch Service likely require IAM, AWS Signature Version 4 request signing is not currently implemented. Other providers have their own schemes — API keys, bearer tokens, mutual TLS — and none are implemented either.

If you use OpenSearch through AWS or another managed provider and would like `pplquery` to work there, please open a pull request or an issue at [https://codeberg.org/brainbuz/pplquery](https://codeberg.org/brainbuz/pplquery).

# No SQL Support

Conceptually on the Perl side it would be easy to add support for OpenSearch SQL. The VSCode extension has syntax highlighting and suggestions which is where more work and maintenance would like. Of the two SQL has a significant functionality deficit, limiting its usefulness. At present there is no plan to add it, it is a future consideration.

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
