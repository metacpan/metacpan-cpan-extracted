# Releasing createsend-perl

## Requirements

- You must have a [PAUSE](https://pause.perl.org/) account and must be a maintainer of the [Net::CampaignMonitor](https://metacpan.org/module/Net::CampaignMonitor) module.

## Prepare the release

- Increment version constants in the following files, ensuring that you use [Semantic Versioning](http://semver.org/):
  * `lib/Net/CampaignMonitor.pm` (both `$VERSION` _and_ the `pod` documentation section)
  * `META.yml`
- Add an entry to `HISTORY.md` which clearly explains the new release.
- Write `Makefile` and run tests:

  ```
  perl Makefile.PL && make test
  ```

- Commit your changes:

  ```
  git commit -am "Version X.Y.Z"
  ```

- Tag the new version:

  ```
  git tag -a vX.Y.Z -m "Version X.Y.Z"
  ```

- Push your changes to GitHub, including the tag you just created:

  ```
  git push origin master --tags
  ```

- Ensure that all [tests](https://travis-ci.org/campaignmonitor/createsend-perl) pass.

## Package the module

```
perl package.pl vX.Y.Z
```

This packages a distribution to a file named something like `../Net-CampaignMonitor-vX.Y.Z.tar.gz`. You're now ready to release the package.

## Release the module

Log in to [PAUSE](https://pause.perl.org/) and choose the _Upload a file to CPAN_ option from the menu on the left hand side.

Then click _Choose File_, choose the `Net-CampaignMonitor-vX.Y.Z.tar.gz` file you packaged in the previous step, and click _Upload this file from my disk_ to upload the distribution.

You should receive an email confirming the upload, as well as an email confirming that the package has been indexed by the PAUSE indexer. All done!
