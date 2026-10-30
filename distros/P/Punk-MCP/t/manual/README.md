# Manual gates

A passing suite proves the plugin agrees with itself. These runs prove that
real clients, written by other people against the published specification,
work against it. Run them before a release and record the outcome under
each section, with the client's version and the date.

The application for all of them is the example:

    BOOKSHOP_ADMIN_KEY=k plackup -s Hyperman -p 5000 example/app.psgi

## 1. The MCP Inspector over HTTP

    npx @modelcontextprotocol/inspector

Connect to `http://localhost:5000/mcp` with the Streamable HTTP transport,
once in direct mode (the browser talks to the server, so CORS is exercised)
and once through the Inspector's proxy. For direct mode the application
needs `cors origins => ['http://localhost:6274']`.

It must show, with no hint from us:

1. `initialize` with the bookshop's name, title and instructions, and an
   `Mcp-Session-Id`.
2. **Tools.** `search_books` listed with its schema and annotations, and
   called with `q = dune`: a structured result. `add_book` not listed until
   the `X-Admin-Key: k` header is set, then listed and callable.
3. **Resources.** `books://catalog` listed and read, and the `books://{id}`
   template listed and read for id 3.
4. **Prompts.** `recommend` listed, its `mood` argument required, and got.
5. **Logging.** Set the level to `info`, call `search_books`, and see the
   log message.
6. **Subscriptions.** Subscribe to `books://catalog`, call `add_book`, and
   see `notifications/resources/updated` arrive on the server stream.
7. **Progress.** A tool declared `stream => 1` that calls `mcp_progress`
   shows its progress (add one to the example for the run).
8. **OAuth.** Against an application with `oauth` and a Punk-OAuth2
   authorization server: the Inspector finds the RFC 9728 document from the
   401, registers, runs PKCE with `resource`, and calls a tool.

Outcome: not yet run.

## 2. Claude Code over HTTP and over stdio

    claude mcp add --transport http bookshop http://localhost:5000/mcp
    claude mcp add bookshop-stdio -- punk mcp --dir example

In a session, ask for a book about deserts. Claude must list the tools,
call `search_books`, and read `books://catalog` or a book when it needs
to. Over stdio, check `punk doctor` in `example/` shows the `Punk::MCP`
row.

Outcome: not yet run.

## 3. A Claude.ai custom connector

Against a deployed copy of the example with `oauth` on, added as a custom
connector. The owner's call: it needs a public host.

Outcome: not yet run.
