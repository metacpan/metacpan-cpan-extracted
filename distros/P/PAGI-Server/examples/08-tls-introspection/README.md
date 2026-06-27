# 08 – TLS Extension Introspection

Reads `scope->{extensions}{tls}` when present and reports certificate/version/cipher data back to the client. Falls back gracefully for non-TLS requests.

## Quick Start

**1. Start the server with TLS:**

```bash
# Generate self-signed cert for testing (if needed)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=localhost"

# Start with TLS enabled
pagi-server --app examples/08-tls-introspection/app.pl --port 5000 \
  --ssl-cert cert.pem --ssl-key key.pem
```

**2. Demo with curl:**

```bash
# HTTPS request - shows TLS info as JSON (versions/ciphers are raw hex codes)
curl -k https://localhost:5000/
# => TLS info:
# => {
# =>    "tls_version" : "0x0304",
# =>    "cipher_suite" : "0x1302",
# =>    "client_cert" : null
# => }

# HTTP request (without TLS) - shows fallback message
curl http://localhost:5000/
# => Connection is not using TLS
```

**Note:** Use `-k` flag with curl to accept self-signed certificates. The
`tls_version`/`cipher_suite` values are the raw TLS codes (e.g. `0x0304` is
TLS 1.3, `0x1302` is `TLS_AES_256_GCM_SHA384`); `client_cert` is `null` unless
the client presents a certificate.

## Spec References

Covered by the PAGI specification in the upstream PAGI distribution
(`PAGI::Spec` POD and protocol documents, https://github.com/jjn1056/pagi):

- TLS extension
- HTTP response events
