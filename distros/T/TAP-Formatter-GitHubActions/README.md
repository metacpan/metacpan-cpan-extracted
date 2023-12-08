TAP::Formatter::GitHubActions
=============================

Provide a Formatter for TAP::Harness that outputs Error messages for
[GitHub Actions (GHA)][0].

It's very alpha but does the best to grab out of the comments provided in the
TAP verbose output the file & line and any extra context to print in the
GHA annotations.

It converts TAP output like:
```
t/02-singleton.t .. 
# [... snip ...]
# Subtest: Save
    not ok 1 - Init state

    #   Failed test 'Init state'
    #   at t/02-singleton.t line 14.
    # died: 1 at t/02-singleton.t line 14.
# [... snip ...]
```

To:

```
# [... snip ...]
= GitHub Actions Report =
::notice file=t/02-singleton.t,line=1,title=More details::See the full report in: %WORKFLOW_URL%
::error file=t/02-singleton.t,line=14,title=1 failed test::Failed test 'Init state'%0A--- CAPTURED CONTEXT ---%0Adied: 1 at t/02-singleton.t line 14.%0A---  END OF CONTEXT  ---
# [... snip ...]
```

And those annotations render in PR's like so:
![github error annotation](./images/github-annotation-on-files.png)

In case your run has too many errors (see **Limitations** below) you can also
explore the workflow summary that looks like this:

![github workflow summary](./images/github-workflow-step-summary.png)


INSTALLATION
------------
To install this module the good ol' way, type the following:

```bash
perl Makefile.PL
make
make test
make install
```

With `cpanm`, add a feature:

```perl
# cpanfile

feature 'ci' => sub {
  requires 'TAP::Formatter::GitHubActions';
};
```

and then install it:

```bash
# assuming you're in the same dir where the cpanfile resides.
cpanm --installdeps . --with-feature=ci
```

USAGE
-----

```bash
prove --merge --formatter TAP::Formatter::GitHubActions
```

For more accurate messages:

```bash
T2_FORMATTER=YAMLEnhancedTAP prove --merge --formatter TAP::Formatter::GitHubActions
```

`Test2::Formatter::YAMLEnhancedTAP` is pulled automatically with this module,
although it's not required for it to work.

LIMITATIONS
-----------

As of writting (3.12.2023), there is a max of 10 annotations per step, 50 per
workflow.

That means: If your test result has more than 10 failures reported, you'll only
see the first 10.

To overcome this, when running under GitHub Actions (detected via
`GITHUB_ACTIONS` env var), the formatter writes into the workflow summary and
then writes one notice on the very top of the failing file with a link to the
summary.

It's not perfect, but gets the work done.

Follow the discussions on GitHub Community, for more updates:
- https://github.com/orgs/community/discussions/26680#discussioncomment-3252835
- https://github.com/orgs/community/discussions/68471


DEPENDENCIES
------------
This module requires these other modules and libraries:

  - `TAP::Harness`
  - `Test2::Formatter::YAMLEnhancedTAP` (optional runtime dep)

COPYRIGHT AND LICENCE
---------------------
Put the correct copyright and licence information here.

Copyright (C) 2023 by Jose D. Gómez R.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.38.0 or,
at your option, any later version of Perl 5 you may have available.


[0]: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-error-message
