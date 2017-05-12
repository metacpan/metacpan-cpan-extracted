# Contributing

Interested in contributing to RiveScript? Great!

First, check the general contributing guidelines for RiveScript and its primary
implementations found at <http://www.rivescript.com/contributing> - in
particular, understand the goals and scope of the RiveScript language and the
style guide for the Perl implementation.

# Quick Start

Fork, then clone the repo:

```bash
$ git clone git@github.com:your-username/rivescript-perl.git
```

Install the Perl module `JSON` if you intend to use the built-in interactive
`rivescript` script for testing.

Make your code changes and test them by using the built-in interactive mode of
RiveScript, e.g. by running:

```bash
$ perl -Ilib bin/rivescript
```

Make sure the unit tests still pass. Run `perl Makefile.PL` to generate the
Makefile and then run `make && make test`

Push to your fork and [submit a pull request](https://github.com/kirsle/rivescript-perl/compare/).

At this point you're waiting on me. I'm usually pretty quick to comment on pull
requests (within a few days) and I may suggest some changes or improvements
or alternatives.

Some things that will increase the chance that your pull request is accepted:

* Follow the style guide at <http://www.rivescript.com/contributing>
* Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).
