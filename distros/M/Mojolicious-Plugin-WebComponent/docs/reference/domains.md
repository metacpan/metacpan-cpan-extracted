# Domains

One domain area; no `CONTEXT.md` or `CONTEXT-MAP.md` exists yet.

| Area | Code | Context |
|------|------|---------|
| Web component serving (helper, route, template injection, checksum URL) | `lib/Mojolicious/Plugin/WebComponent.pm` | none; decision record `docs/adr/0001-component-url-carries-a-content-checksum.md` |

## Term gaps

Domain words the code or docs use that no context file defines (offer to
`name-it`):

| Word | Where it appears |
|------|------------------|
| component (script plus template pair) | helper name `component`, route `*component`, POD |
| template (`tmpl`) | `let tmpl;` marker in component scripts, `template` option and param, `template_path` |
| checksum (the URL fingerprint) and `requestId` (its override) | route pattern `:checksum`, helper option `requestId`, `_checksum`, ADR 0001 |
| asset dir | `$app->static->asset_dir` used in `_content` (`:72`) |
