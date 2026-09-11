# Testing

```sh
prove -Ilib -It/lib -lv t
```

The suite runs against a mock OpenSearch server by default, and against a real cluster when you point it at one.

## Environment variables

| Variable | Effect |
| --- | --- |
| `PPLQUERY_TEST_URL` | **The live server's URL**. Set it to test against a real cluster; leave it unset for the mock. |
| `PPLQUERY_TEST_USER` | Basic-auth username for the live server. Set it together with `PPLQUERY_TEST_PASSWORD`. |
| `PPLQUERY_TEST_PASSWORD` | Basic-auth password for the live server. Set it together with `PPLQUERY_TEST_USER`. |

Omit the username and password for an unauthenticated cluster.

## Mock mode (default)

With `PPLQUERY_TEST_URL` unset, the integration test starts a deterministic mock server on an automatically allocated loopback port. The test clears inherited production and test credentials before starting the mock, since the mock speaks plain HTTP.

> **The live suite writes to the cluster.** It creates an index named `pplquery-test-<timestamp>-<pid>`, indexes documents into it, and deletes it at the end. Use a cluster where that is acceptable, with an account permitted to create and drop indices. An interrupted run can leave a `pplquery-test-*` index behind.
