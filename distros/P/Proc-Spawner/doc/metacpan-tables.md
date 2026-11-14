# How MetaCPAN shows a table: a test page

MetaCPAN renders the `.md` files of a distribution (under `/release/.../view/doc/...`), but not their pipe
tables.  This page holds one table in five forms, to see which of them MetaCPAN shows well; the documents
will use the form chosen (`TODO`, item A15).  The table is three rows of the version table at the end of
[`README.md`](README.md); one cell holds a link, to see whether links inside a table work.

## 1. A pipe table (GitHub Flavored Markdown)

| Label | The code |
|---|---|
| post-0.03 | 0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (`Changes`); unreleased; measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3) |
| 0.04 | the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents and decision pages of only historical interest removed; the figures of post4-0.03 checked again on it (the same per-sample results) |
| 0.05 | the release of 2026-11-05: post4-0.04 with the version number 0.05; the figures of post4-0.04 hold for it (the measured files differ only in `$VERSION`) |

## 2. A table in raw HTML

<table>
<tr><th>Label</th><th>The code</th></tr>
<tr><td>post-0.03</td><td>0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (<code>Changes</code>); unreleased; measured 2026-11-03 (<a href="large-subset/large-subset-state.md"><code>large-subset/large-subset-state.md</code></a>, section 3)</td></tr>
<tr><td>0.04</td><td>the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents and decision pages of only historical interest removed; the figures of post4-0.03 checked again on it (the same per-sample results)</td></tr>
<tr><td>0.05</td><td>the release of 2026-11-05: post4-0.04 with the version number 0.05; the figures of post4-0.04 hold for it (the measured files differ only in <code>$VERSION</code>)</td></tr>
</table>

## 3. Preformatted text, indented by four spaces

    Label      The code
    ---------  ----------------------------------------------------------------------------------------
    post-0.03  0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (Changes); unreleased;
               measured 2026-11-03 (large-subset/large-subset-state.md, section 3)
    0.04       the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents and
               decision pages of only historical interest removed; the figures of post4-0.03 checked
               again on it (the same per-sample results)
    0.05       the release of 2026-11-05: post4-0.04 with the version number 0.05; the figures of
               post4-0.04 hold for it (the measured files differ only in $VERSION)

## 4. Preformatted text, fenced

```text
Label      The code
---------  ----------------------------------------------------------------------------------------
post-0.03  0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (Changes); unreleased;
           measured 2026-11-03 (large-subset/large-subset-state.md, section 3)
0.04       the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents and
           decision pages of only historical interest removed; the figures of post4-0.03 checked
           again on it (the same per-sample results)
0.05       the release of 2026-11-05: post4-0.04 with the version number 0.05; the figures of
           post4-0.04 hold for it (the measured files differ only in $VERSION)
```

## 5. No table: a list, one item per row

- **post-0.03**: 0.03 plus item P6 of "Shell Corpus Gaps" and three detector fixes (`Changes`); unreleased;
  measured 2026-11-03 ([`large-subset/large-subset-state.md`](large-subset/large-subset-state.md), section 3)
- **0.04**: the release of 2026-11-03: post4-0.03 with the version number 0.04 and the documents and decision
  pages of only historical interest removed; the figures of post4-0.03 checked again on it (the same
  per-sample results)
- **0.05**: the release of 2026-11-05: post4-0.04 with the version number 0.05; the figures of post4-0.04 hold
  for it (the measured files differ only in `$VERSION`)
