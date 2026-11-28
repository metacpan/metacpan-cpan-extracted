# Music::NWC2MusicXML website

Static pages for Music::NWC2MusicXML. No scripts, no external fonts, no CDN:
the pages need nothing but the files here.

## Deploying on Apache

Copy this whole `website` directory into the server's document root:

    cp -r website /var/www/html/nwc2musicxml

Then browse to `http://host/nwc2musicxml/` — the `index.html` at the top of the
directory redirects to `html/index.html`. Every link is relative, so the site
also works if the document root is this directory itself, or `website/html`.

If the server does not already do so, `DirectoryIndex index.html` (the Apache
default) is all that is required. Nothing needs CGI, PHP, rewrites or modules.

## Layout

- `html/` — the pages, linked to each other by file name.
- `css/site.css` — one stylesheet, referenced as `../css/site.css`.
- `index.html` — redirect to `html/index.html`.
- `robots.txt`, `sitemap.xml` — the only two files that name the host, as
  `https://nwc2musicxml.nigelhorne.com/`. If the site moves, or is served from
  a subdirectory rather than its own virtual host, update the URLs in those two
  files; nothing else contains an absolute URL.

## Pages

| Page | Content |
|------|---------|
| `index.html` | What the module does, the three-stage pipeline, what it does not do |
| `install.html` | CPAN and checkout installs, prerequisites, what gets installed |
| `quickstart.html` | One file to MuseScore, then a folder, then the Perl API |
| `commands.html` | The `nwc2musicxml` synopsis, options and exit codes |
| `api.html` | `new`, `convert`, `batch_convert`, `diagnostics`, the stages on their own |
| `formats.html` | Every NWC construct that has a MusicXML destination |
| `limitations.html` | Multi-voice staves, page size, and the unvalidated paths |
| `changelog.html` | The highlights of each release |

## Shared conventions

This site is one of five with the same look and feel — the others are
App::Actions, App::FileSync, App::Test::Generator and Database::BI.
`css/site.css` is **byte-identical in all five**; a change to it belongs in all
five at once, or the sites drift apart again.

Every page uses the same shell:

    <a class="skip" href="#main">Skip to content</a>
    <header class="site-header">
        <div class="wrap header-inner">
            <a class="brand" href="index.html">
                <span class="brand-name">Music::NWC2MusicXML</span>
                <span class="brand-tag">NoteWorthy Composer scores to MusicXML</span>
            </a>
            <nav class="site-nav" aria-label="Main"> ...
    <main id="main" class="wrap">
    <footer class="site-footer"><div class="wrap">

and the same `<head>`:

- `<meta name="viewport" content="width=device-width, initial-scale=1">`
- a unique `<title>` and `<meta name="description">` per page
- `<link rel="canonical" href="<this file's name>">`
- the two `theme-color` hints (light and dark)
- `og:type`, `og:site_name`, `og:title`, `og:description` and
  `twitter:card`
- `application/ld+json` on the home page only

The top-level `index.html` is a redirect stub: it carries `noindex, follow` so
it cannot compete in search results with the real home page.

## Mobile

Desktop is the primary target. Below 46rem the navigation becomes a single
horizontally scrolling row inside the sticky header; below 34rem the cards
become one column and the page gutters tighten. Tables live in
`<div class="table-wrap">` so a wide one scrolls sideways instead of pushing
the page out.

## Adding a page

Copy an existing page, then update the `<title>`, the description, the
canonical, `og:title`/`og:description`, the `<h1>` and the `aria-current` on
its own nav link — and add a nav entry to every other page, plus the page to
`sitemap.xml`.
