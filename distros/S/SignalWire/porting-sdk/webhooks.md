# Webhook Signature Validation

SignalWire signs outbound webhook requests (cXML, SWML, RELAY async events) with an HMAC derived from a **Signing Key** the customer copies from their Dashboard → API Credentials page. Every SDK that exposes a webhook handler MUST provide a validator so users can confirm a request came from SignalWire before acting on it.

Two on-the-wire schemes exist and **both must be supported**. The `@signalwire/web-api` reference tries Scheme A first and falls back to Scheme B — every port should do the same.

## The Header

`X-SignalWire-Signature` — present on every signed request.

For compatibility with legacy integrations, the cXML/Compatibility scheme also accepts `X-Twilio-Signature` as an alias. Ports that expose a cXML-compatibility validator SHOULD honor both header names; ports targeting only the SWML/RELAY surface MAY ignore the legacy header.

## The Signing Key

- Labeled **"Signing Key"** in the SignalWire Dashboard → API Credentials.
- Passed to the validator as a UTF-8 string.
- MUST be treated as secret: never log, never include in error messages, never echo to clients.
- SDKs SHOULD read `SIGNALWIRE_SIGNING_KEY` from the environment as a fallback when no explicit key is passed.

---

## Scheme A — RELAY / SWML (JSON body, hex digest)

Used for: SWML callbacks, SWAIG function dispatch, `post_prompt` summaries, RELAY async event webhooks — anything the platform posts as `application/json`.

### Algorithm

```
signature = lowercase_hex( HMAC-SHA1( signingKey, url + rawBody ) )
```

Where:
- `url` is the **full URL SignalWire POSTed to**, including scheme, host, port (if non-standard), path, and query string — exactly as the platform saw it when it fired the request.
- `rawBody` is the **raw UTF-8 request body bytes** as a string, **before** any JSON parsing. The body MUST NOT be re-serialized by the SDK; re-serialization changes byte order and whitespace and breaks the signature.
- Result is **hex**, lowercase, compared byte-for-byte.

### Reference implementation (JavaScript — `@signalwire/web-api`)

```js
const hmac = createHmac('sha1', privateKey);
hmac.update(`${url}${rawBody}`);
const valid = hmac.digest('hex') === header;
```

### Test vector

| Field | Value |
|---|---|
| Signing Key | `PSKtest1234567890abcdef` |
| URL | `https://example.ngrok.io/webhook` |
| Raw body | `{"event":"call.state","params":{"call_id":"abc-123","state":"answered"}}` |
| Expected header | `c3c08c1fefaf9ee198a100d5906765a6f394bf0f` |

Port authors: run your implementation against this exact triple and assert the digest matches before shipping.

---

## Scheme B — Compatibility / cXML (form-encoded, base64 digest)

Used for: cXML webhooks (LaML), legacy Twilio-compatible endpoints, and any endpoint where SignalWire POSTs `application/x-www-form-urlencoded`.

### Algorithm — form-encoded

```
sortedParams  = params sorted by key name, ASCII ascending
concatenated  = for each (key, value) in sortedParams: key + value
                    (if value is an array: repeat key for each element, in original order)
signingString = url + concatenated
signature     = base64( HMAC-SHA1( signingKey, signingString ) )
```

### Algorithm — JSON bodies on the compat surface (`bodySHA256` query param)

When SignalWire posts JSON to a cXML-style endpoint, it appends a `bodySHA256` query parameter to the URL instead of including it in the signed params. In that case:

```
1. Validate the URL using the form algorithm with an EMPTY params object
   (the bodySHA256 query param becomes part of `url` and is signed that way).
2. Independently validate: sha256_hex(rawBody) == url.query.bodySHA256
3. The request is valid only if BOTH checks pass.
```

### URL port normalization (REQUIRED)

SignalWire's backend signs some requests with the standard port included in the URL (`:443` for `https`, `:80` for `http`) and some without. Validators MUST try **both forms** and accept if either matches:

```
urlWithPort     = url with :443 (https) or :80 (http) inserted if no port is present
urlWithoutPort  = url with any port stripped
```

If the URL already has a non-standard port, use it as-is; skip the with/without variants.

### Array / repeated form keys

Form bodies MAY include repeated keys (e.g. `To=+1…&To=+1…`). Values MUST be sorted **by key only** — within a repeated key, preserve the original submission order, then concatenate `key+value1+key+value2…`.

### Encoding

- Signing string: UTF-8.
- Signature: **base64** (standard, not URL-safe).

### Reference implementation (JavaScript — `@signalwire/compatibility-api`)

```js
function toFormUrlEncodedParam(name, value) {
  if (Array.isArray(value)) {
    return value.map(v => toFormUrlEncodedParam(name, v)).join('');
  }
  return name + value;
}

function getExpectedSignature(key, url, params) {
  const data = Object.keys(params).sort().reduce(
    (acc, k) => acc + toFormUrlEncodedParam(k, params[k]),
    url,
  );
  return createHmac('sha1', key).update(Buffer.from(data, 'utf-8')).digest('base64');
}
```

### Test vector — form-encoded (canonical)

| Field | Value |
|---|---|
| Signing Key | `12345` |
| URL | `https://mycompany.com/myapp.php?foo=1&bar=2` |
| Params (form body) | `CallSid=CA1234567890ABCDE`, `Caller=+14158675309`, `Digits=1234`, `From=+14158675309`, `To=+18005551212` |
| Signing string | `https://mycompany.com/myapp.php?foo=1&bar=2CallSidCA1234567890ABCDECaller+14158675309Digits1234From+14158675309To+18005551212` |
| Expected header | `RSOYDt4T1cUTdK1PDd93/VVr8B8=` |

This is the canonical Twilio test vector; SignalWire's compat scheme matches it exactly.

### Test vector — `bodySHA256` (JSON on compat surface)

| Field | Value |
|---|---|
| Signing Key | `PSKtest1234567890abcdef` |
| Raw body | `{"event":"call.state"}` |
| URL | `https://example.ngrok.io/webhook?bodySHA256=69f3cbfc18e386ef8236cb7008cd5a54b7fed637a8cb3373b5a1591d7f0fd5f4` |
| Expected header | `dfO9ek8mxyFtn2nMz24plPmPfIY=` |

The `bodySHA256` value is `sha256_hex('{"event":"call.state"}')`. The base64 signature is computed over the full URL (with the `bodySHA256` query param) and an empty params object.

---

## Combined Validator (what the SDK exposes)

Every port MUST expose a single public function that tries both schemes and returns a boolean:

```
function validateWebhookSignature(signingKey, signatureHeader, url, rawBody) -> boolean

  // Scheme A — RELAY/JSON (hex)
  if hex(hmac_sha1(signingKey, url + rawBody)) == signatureHeader:
      return true

  // Scheme B — Compat (base64 form-encoded)
  parsedParams = parse rawBody as application/x-www-form-urlencoded
                 (or {} if not form-encoded and no params are signable)

  for candidateUrl in [urlWithPort, urlWithoutPort]:
      expected = base64(hmac_sha1(signingKey, candidateUrl + concatSortedParams(parsedParams)))
      if timing_safe_equal(signatureHeader, expected):

          // If URL has ?bodySHA256=<hex>, also verify the body hash
          if candidateUrl has bodySHA256 query param:
              if sha256_hex(rawBody) != bodySHA256:
                  continue
          return true

  return false
```

Ports MAY expose the two schemes as separate functions (`validateJsonWebhook`, `validateFormWebhook`) for users who know which scheme applies, but the combined entry point is REQUIRED for drop-in parity with `@signalwire/compatibility-api`'s `RestClient.validateRequest(...)`.

### Compat-shape drop-in alias

Ports MUST also expose a second entry point named `validateRequest` (language-idiomatic casing) with the legacy `@signalwire/compatibility-api` signature, so users migrating from the old SDK can change only the import:

```
validateRequest(signingKey, signature, url, parsedParamsOrRawBody) -> boolean
```

If the fourth argument is a string, delegate to `validateWebhookSignature` (Scheme A, then B-with-parsed-form if applicable). If it's an object/dict, treat it as pre-parsed form params and run Scheme B directly. This matches the legacy API shape.

---

## Required SDK Behaviors

### Timing-safe comparison
All signature comparisons MUST use a constant-time byte-compare (`crypto/subtle.ConstantTimeCompare` in Go, `crypto.timingSafeEqual` in Node, `hmac.compare_digest` in Python, equivalent in Ruby/Java/Perl/C++). Plain `==` on the full digest string leaks the secret over repeated requests.

### Raw body read-once
The validator MUST receive the **raw body bytes as sent**. This means the SDK's HTTP layer has to capture the body before any framework-level JSON/form parser consumes it. Typical implementations:

- Capture body as a string in a middleware ahead of any parser; stash on the request context.
- Or pass a raw-body callback into the parser.

Ports that only expose a parsed-object API (e.g. `req.body` is already a dict) are broken for the JSON/RELAY scheme — JSON key ordering and whitespace aren't preserved through parse+reserialize.

### URL reconstruction behind proxies
The `url` passed to the validator MUST match the URL SignalWire POSTed to, not the internal URL the SDK sees behind a reverse proxy or tunnel. SDKs MUST honor either:
- An explicit `url` parameter the caller provides (always supported), OR
- `X-Forwarded-Proto` / `X-Forwarded-Host` headers when `trustProxy` (or equivalent) is enabled, OR
- An `SWML_PROXY_URL_BASE` env var when set.

Fall back to `scheme://host[:port]/path?query` derived from the raw request only when none of the above apply.

### Error modes — what to return

| Condition | Behavior |
|---|---|
| Valid signature | return `true` |
| Invalid signature | return `false` |
| Missing header | return `false` (never throw) |
| Missing signing key | throw / error out — this is a programming error, not a validation failure |
| Non-string rawBody when expected | throw with a clear message (e.g. "rawBody must be a string; did you pass the parsed JSON by mistake?") |

Validators MUST NOT log or otherwise expose which branch failed, which scheme was tried, or what the expected signature was.

---

## Suggested Public API (per-language)

Ports SHOULD follow their language's conventions for naming but MUST keep the parameter order **(signingKey, signatureHeader, url, rawBody)** to make code-porting between languages mechanical.

| Language | Signature |
|---|---|
| TypeScript | `validateWebhookSignature(signingKey: string, signature: string, url: string, rawBody: string): boolean` |
| Python | `validate_webhook_signature(signing_key: str, signature: str, url: str, raw_body: str) -> bool` |
| Go | `ValidateWebhookSignature(signingKey, signature, url, rawBody string) bool` |
| Ruby | `validate_webhook_signature(signing_key, signature, url, raw_body) -> Boolean` |
| Java | `boolean validateWebhookSignature(String signingKey, String signature, String url, String rawBody)` |
| Perl | `sub validate_webhook_signature { my ($signing_key, $signature, $url, $raw_body) = @_; ... }` |
| C++ | `bool ValidateWebhookSignature(std::string_view signing_key, std::string_view signature, std::string_view url, std::string_view raw_body)` |

### Framework adapter (required when the language has a dominant HTTP framework)

Ship a middleware / decorator that plugs into the language's canonical HTTP stack and:

1. Reads the raw body and caches it on the request context.
2. Pulls the `X-SignalWire-Signature` header.
3. Reconstructs the full public URL (honoring proxy headers / env vars).
4. Calls the validator.
5. On failure: respond `403 Forbidden`, no body detail. Do not call the downstream handler.
6. On success: expose the cached raw body to the downstream handler (so it can re-parse without re-reading the stream).

| Language | Framework |
|---|---|
| TypeScript | Hono middleware (primary); Express adapter if demand exists |
| Python | FastAPI dependency + Flask before_request decorator |
| Go | `http.Handler` middleware |
| Ruby | Rack middleware + Rails controller concern |
| Java | Servlet filter + Spring interceptor |
| Perl | Plack middleware |
| C++ | Crow / Pistache adapter as applicable |

### AgentBase integration (REQUIRED if the port exposes AgentBase)

If the port exposes an `AgentBase` equivalent, it MUST:

- Accept a `signingKey` option (and fall back to `SIGNALWIRE_SIGNING_KEY`).
- When set, auto-mount the signature-validation middleware on `POST /`, `POST /swaig`, `POST /post_prompt` (and any other signed webhook route).
- Unsigned requests MUST be rejected with `403` when `signingKey` is configured.
- When `signingKey` is not set, AgentBase MUST NOT silently accept unsigned requests in production; SDKs SHOULD log a prominent warning on startup (e.g. `[signalwire] webhook signature validation is disabled — set signingKey or SIGNALWIRE_SIGNING_KEY to enable`).

Ports that do NOT ship an AgentBase (e.g. minimal bindings) only need to expose the standalone validator and framework adapter; skip the auto-mount behavior.

---

## Reference Implementations

When in doubt, port from these:

- **Scheme A (RELAY/JSON):** `@signalwire/web-api` → `src/validateRequest.ts`
  <https://www.npmjs.com/package/@signalwire/web-api>
- **Scheme B (Compat/cXML):** `@signalwire/compatibility-api` → `lib/webhooks/webhooks.js` (`getExpectedTwilioSignature`, `validateRequest`, `validateBody`)
  <https://www.npmjs.com/package/@signalwire/compatibility-api>

Both are npm packages; `npm pack <name>` gives you the full source.

---

## Out of Scope

The following are **deliberately not part of this spec** and SHOULD NOT be added by port authors without a follow-up spec:

- **Signature rotation / multiple-key acceptance.** The platform signs with one active key at a time. Multi-key rollover is a future concern.
- **Timestamp / replay protection.** The SignalWire signing scheme has no timestamp; replay protection is the application's responsibility.
- **Non-SignalWire signature schemes.** If you need to validate Twilio-signed requests in a SignalWire SDK, use the Twilio SDK.

---

## Testing Requirements

Every port's test suite MUST include:

- [ ] Scheme A positive case — known URL + body + key → expected hex digest (use the canonical vector above)
- [ ] Scheme A negative case — tampered body returns `false`
- [ ] Scheme B positive case (form-encoded) — canonical Twilio test vector above
- [ ] Scheme B with `bodySHA256` query param — JSON body + URL-embedded hash (use the canonical vector above)
- [ ] Scheme B URL port normalization — same signature accepted with and without standard port
- [ ] Scheme B repeated form keys — `To=a&To=b` hashes deterministically
- [ ] Missing header returns `false` (not exception)
- [ ] Missing signing key raises an error
- [ ] Malformed signature (wrong length, wrong encoding) returns `false` without throwing
- [ ] Framework adapter: 403 on invalid, 200 on valid, raw body forwarded to handler
- [ ] AgentBase integration (where applicable): signed request accepted, unsigned rejected

Commit these tests with the port.
