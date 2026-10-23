---
status: accepted
---

# The component script URL carries a checksum of its content

The script URL used to carry a per-request id, so no two page views shared a URL and browsers could never cache the
script. The URL now carries the SHA-1 of the script as served (template injected), computed by the helper at page
render time and checked by the route when the script is fetched. A matching checksum is answered with
`Cache-Control: public, max-age=31536000, immutable`; any other is answered with the current script and `no-cache`,
so a stale page cannot pin old content. The `requestId` helper option stays as an explicit override and is also
`no-cache`. This changes the public URL shape (`:req` became `:checksum`) and is released as 0.08.

Keeping the request id and leaving caching to the app was rejected: it leaves every page view re-rendering and
re-downloading each component. A registry of components, as AssetPack keeps, was rejected: the path allowlist already
bounds what is served.

## Consequences

- The helper renders each template to fingerprint it, so a page view renders every component twice.
- The helper renders with the page's controller and the route with the script request's, so a template that reads the
  session or the current route can render differently in each. The checksum then never matches and the script is
  served `no-cache`: correct, but uncached.
- A template that prints the current user's data matches its own checksum and is sent `public`, so a shared cache in
  front of the app could store it. The route cannot tell such a template from a shared one; the POD tells authors to
  keep user data out of component templates.
