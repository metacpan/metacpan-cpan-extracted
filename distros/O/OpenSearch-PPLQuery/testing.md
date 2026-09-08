# Testing

```sh
prove -Ilib -It/lib -lv t
```

The suite runs against a mock OpenSearch server by default, and against a real cluster when you point it at one.

## Environment variables

| Variable | Effect |
| --- | --- |
| `OPENSEARCHTEST` | **The live server's URL**, not a flag. Set it to test against a real cluster; leave it unset for the mock. |
| `OPENSEARCH_USERNAME` | Basic-auth username for the live server. Enables authentication when set. |
| `OPENSEARCH_PASSWORD` | Basic-auth password, used with the username above. |

## Mock mode (default)

With `OPENSEARCHTEST` unset, the suite starts a deterministic mock server on `127.0.0.1:9200`. It fails if that port cannot be bound rather than connecting to whatever is already listening. The suite clears `OPENSEARCH_USERNAME` and `OPENSEARCH_PASSWORD` for itself, since the mock speaks plain HTTP.

Omit the username and password for an unauthenticated cluster.

> **The live suite writes to the cluster.** It creates an index named `pplquery-test-<timestamp>-<pid>`, indexes documents into it, and deletes it at the end. Use a cluster where that is acceptable, with an account permitted to create and drop indices. An interrupted run can leave a `pplquery-test-*` index behind.
