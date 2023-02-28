# Reply-Plugin-Prompt

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/Freed-Wu/Reply-Plugin-Prompt/main.svg)](https://results.pre-commit.ci/latest/github/Freed-Wu/Reply-Plugin-Prompt/main)

[![github/downloads](https://shields.io/github/downloads/Freed-Wu/Reply-Plugin-Prompt/total)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/releases)
[![github/downloads/latest](https://shields.io/github/downloads/Freed-Wu/Reply-Plugin-Prompt/latest/total)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/releases/latest)
[![github/issues](https://shields.io/github/issues/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/issues)
[![github/issues-closed](https://shields.io/github/issues-closed/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/issues?q=is%3Aissue+is%3Aclosed)
[![github/issues-pr](https://shields.io/github/issues-pr/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/pulls)
[![github/issues-pr-closed](https://shields.io/github/issues-pr-closed/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/pulls?q=is%3Apr+is%3Aclosed)
[![github/discussions](https://shields.io/github/discussions/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/discussions)
[![github/milestones](https://shields.io/github/milestones/all/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/milestones)
[![github/forks](https://shields.io/github/forks/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/network/members)
[![github/stars](https://shields.io/github/stars/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/stargazers)
[![github/watchers](https://shields.io/github/watchers/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/watchers)
[![github/contributors](https://shields.io/github/contributors/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/graphs/contributors)
[![github/commit-activity](https://shields.io/github/commit-activity/w/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/graphs/commit-activity)
[![github/last-commit](https://shields.io/github/last-commit/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/commits)
[![github/release-date](https://shields.io/github/release-date/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/releases/latest)

[![github/license](https://shields.io/github/license/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt/blob/main/LICENSE)
[![github/languages](https://shields.io/github/languages/count/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt)
[![github/languages/top](https://shields.io/github/languages/top/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt)
[![github/directory-file-count](https://shields.io/github/directory-file-count/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt)
[![github/code-size](https://shields.io/github/languages/code-size/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt)
[![github/repo-size](https://shields.io/github/repo-size/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt)
[![github/v](https://shields.io/github/v/release/Freed-Wu/Reply-Plugin-Prompt)](https://github.com/Freed-Wu/Reply-Plugin-Prompt)

[![cpan/v](https://img.shields.io/cpan/v/Reply-Plugin-Prompt)](https://metacpan.org/pod/Reply::Plugin::Prompt)

[Reply](https://metacpan.org/pod/Reply) plugin for
[powerlevel10k](https://github.com/romkatv/powerlevel10k) style prompt.
It is an enhancement of
[Reply::Plugin::FancyPrompt](https://metacpan.org/pod/Reply::Plugin::FancyPrompt).

Your perl deserves a beautiful REPL.

![screenshot](https://user-images.githubusercontent.com/32936898/221406537-5c9222e2-23ed-423c-9860-671b06421aef.jpg)

## Install

```bash
cpan Reply::Plugin::Prompt
```

Enable this plugin in your `~/.replyrc`:

```dosini
[Prompt]
```

## Build

```bash
./Makefile.PL
cp MANIFEST.SKIP.bak MANIFEST.SKIP
make manifest
make dist
```

## Configure

### Section Order

```perl
@sections = ( 'result', 'os', 'version', 'path', 'time' );
```

### Section Colors

```perl
%section_colors = (
    'result'  => 'yellow on_red',
    'os'      => 'black on_yellow',
    'version' => 'blue on_black',
    'path'    => 'white on_blue',
    'time'    => 'black on_white',
);
```

### Section Separator

```perl
$sep = '';
```

### Whitespaces Which Padded Around Section Text

```perl
$insert_text = ' %s ';
```

### Section Text

```perl
$insert_result  = '✘ %s';
$insert_version = ' %s';
$insert_os      = '%s';
$insert_time    = ' %s';
```

### Time Format

```perl
$time_format = '%H:%M:%S';
```

### Prompt Character

```perl
$prompt_char = '❯ ';
```

### Configuration File

The configuration file path respects
[XDG](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html),
which is `${XDG_CONFIG_PATH:-$HOME/.config}/reply/prompt.pl`.

## Similar Prompts

See [here](https://github.com/Freed-Wu/my-dotfiles/wiki).
