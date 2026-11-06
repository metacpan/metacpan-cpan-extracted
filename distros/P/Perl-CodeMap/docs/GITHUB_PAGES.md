# Deploy the sample to GitHub Pages

Perl CodeMap has an optional public demo built and deployed by the existing
`.github/workflows/ci.yml` workflow. The generated page is the interactive
CodeMap itself, served as the site's `index.html`.

## One-time setup

1. Create a GitHub repository (for example, `perl-codemap`) and push this
   project, including `.github/workflows/ci.yml`, to its `main` branch.
2. In the repository, open **Settings → Pages**.
3. Under **Build and deployment**, select **GitHub Actions** as the **Source**.
4. Ensure Actions are enabled under **Settings → Actions → General** and that
   the `github-pages` environment is permitted to deploy from `main`
   (if your repository/organization has environment protection policies).
5. Push a commit to `main`. The **CI** workflow runs the Perl and frontend
   tests, builds `_site/index.html`, uploads it as a Pages artifact, and then
   deploys it to the `github-pages` environment.

The live sample is published at:

**[https://interrupt21h.github.io/perl-codemap/](https://interrupt21h.github.io/perl-codemap/)**

The deploy job publishes its actual URL in the GitHub Actions deployment
summary and the repository's **Settings → Pages** view.

## What the workflow actually does

The `build-pages` job runs only after all Perl matrix and frontend CI jobs
succeed and only for a push to `main`:

```sh
mkdir -p _site
perl bin/perl-codemap \
  --root examples/sample \
  --parser lite \
  --include-tests \
  --name 'Perl CodeMap - Live Demo' \
  --output _site/index.html
test -s _site/index.html
grep -q 'Demo::App' _site/index.html
touch _site/.nojekyll
```

The upload action's `path` is **only** `_site`, rather than `.`. The static
HTML includes syntax-highlightable source content from this intentionally
synthetic sample. The demo uses the zero-dependency `lite` parser to make
Pages builds independent of CPAN availability; the separate matrix tests PPI
with PPI installed.

The deployment job uses `pages: write` and `id-token: write` permissions;
it depends on the build artifact and targets the `github-pages` environment.
The source checkout/build jobs only request `contents: read`.

## Publishing safety

**Every GitHub Pages site is publicly accessible.** Do not change the
workflow to scan an employer/customer repository or upload `_site` from
private build output. Generated reports embed source code by default, even
when the original project is private. The demo must remain a synthetic test
fixture. Check sample code in code review before merging.

When you want to change the appearance or features of the demo, update the
visualizer and/or synthetic `examples/sample/` code. Pushing to `main`
regenerates the site automatically. `examples/demo.html` is a checked-in
illustration and is not deployed: the workflow always rebuilds from source.

## Common problems

- **No deployment job runs:** Pages jobs only execute after successful tests
  on pushes to `main`; neither pull requests nor other branches deploy.
- **`configure-pages` fails:** Check that Settings → Pages → Source is set to
  GitHub Actions and that Actions/Pages are allowed by organization policy.
- **Permission or environment error:** Check the `github-pages` environment
  rules and workflow token restrictions. Deployment requires Pages write and
  OIDC token issuance.
- **404:** Check the Pages URL exposed by the deployment job (project sites
  typically have a `/perl-codemap/` path). Verify deployment succeeded.
- **Demo looks out-of-date:** Confirm the last successful CI run on `main`.

References: [GitHub Pages custom workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
and [publishing source settings](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).
