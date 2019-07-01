
# NAME

Pherkin::Extension::Weasel - Pherkin extension for web-testing

# VERSION

0.09

# SYNOPSIS

```yaml
   # In the pherkin config file t/.pherkin.yaml:
   default:
     extensions:
       Pherkin::Extension::Weasel:
         default_session: selenium
         sessions:
            selenium:
              # write screenshots to img/
              screenshots_dir: img
              screenshot_events:
              # generate screenshots before every step
              pre_step: 1
              # and at the end of every scenario
              post_scenario: 1
              base_url: http://localhost:5000
              driver:
                drv_name: Weasel::Driver::Selenium2
                wait_timeout: 3000
                window_size   1024x1280
                caps:
                   port: 4420
```

```perl
  # Which makes the S->{ext_wsl} field available,
  # pointing at the default session, in steps of features or scenarios
  # marked with the '@weasel' tag so in the steps you can use:

  use Weasel::FindExpanders::HTML;

  Then qr/I see an input element with label XYZ/, sub {
    S->{ext_wsl}->page->find('*labelled', text => 'XYZ');
  };
```
# DESCRIPTION

This module implements an extension to [Test::BDD::Cucumber
(aka pherkin)](https://github.com/pjlsergeant/test-bdd-cucumber-perl),
providing access to a
[`Weasel::Session`](https://github.com/perl-weasel/weasel/) and the
following features:

  * Starting sessions for scenarios which need it
  * Taking screenshots on configured events
  * Provide basic steps for
    * Page navigation
    * Page content assertion

Intended features to be implemented:

  * Browser session transcript recording, annotating browser
    manipulation invocations with Weasel function return
    values and screenshots.

(More ideas welcome, please log issues.)

# INSTALLATION

```sh
  # Install Pherkin::Extension::Weasel with its dependencies
  $ cpanm Pherkin::Extension::Weasel

  # Install the (currently only) Weasel web driver
  $ cpanm Weasel::Driver::Selenium2
```

If you want to use the Dojo compatibility widgets, also:

```sh
  cpanm Weasel::Widgets::Dojo
```

# SUPPORT

## BUGS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/pherkin-extension-weasel/issues

## DISCUSSION

Community support is available through
[perl-weasel@googlegroups.com](mailto:perl-weasel@googlegroups.com).

# COPYRIGHT

```
Copyright (c)  2016-2018  Erik Huelsmann
```

# LICENSE

Same as Perl
