# tmux-status-bar

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/Freed-Wu/tmux-status-bar/main.svg)](https://results.pre-commit.ci/latest/github/Freed-Wu/tmux-status-bar/main)
[![github/workflow](https://github.com/Freed-Wu/tmux-status-bar/actions/workflows/main.yml/badge.svg)](https://github.com/Freed-Wu/tmux-status-bar/actions)
[![codecov](https://codecov.io/gh/Freed-Wu/tmux-status-bar/branch/main/graph/badge.svg)](https://codecov.io/gh/Freed-Wu/tmux-status-bar)
[![DeepSource](https://deepsource.io/gh/Freed-Wu/tmux-status-bar.svg/?show_trend=true)](https://deepsource.io/gh/Freed-Wu/tmux-status-bar)

[![github/downloads](https://shields.io/github/downloads/Freed-Wu/tmux-status-bar/total)](https://github.com/Freed-Wu/tmux-status-bar/releases)
[![github/downloads/latest](https://shields.io/github/downloads/Freed-Wu/tmux-status-bar/latest/total)](https://github.com/Freed-Wu/tmux-status-bar/releases/latest)
[![github/issues](https://shields.io/github/issues/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/issues)
[![github/issues-closed](https://shields.io/github/issues-closed/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/issues?q=is%3Aissue+is%3Aclosed)
[![github/issues-pr](https://shields.io/github/issues-pr/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/pulls)
[![github/issues-pr-closed](https://shields.io/github/issues-pr-closed/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/pulls?q=is%3Apr+is%3Aclosed)
[![github/discussions](https://shields.io/github/discussions/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/discussions)
[![github/milestones](https://shields.io/github/milestones/all/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/milestones)
[![github/forks](https://shields.io/github/forks/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/network/members)
[![github/stars](https://shields.io/github/stars/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/stargazers)
[![github/watchers](https://shields.io/github/watchers/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/watchers)
[![github/contributors](https://shields.io/github/contributors/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/graphs/contributors)
[![github/commit-activity](https://shields.io/github/commit-activity/w/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/graphs/commit-activity)
[![github/last-commit](https://shields.io/github/last-commit/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/commits)
[![github/release-date](https://shields.io/github/release-date/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/releases/latest)

[![github/license](https://shields.io/github/license/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar/blob/main/LICENSE)
[![github/languages](https://shields.io/github/languages/count/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar)
[![github/languages/top](https://shields.io/github/languages/top/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar)
[![github/directory-file-count](https://shields.io/github/directory-file-count/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar)
[![github/code-size](https://shields.io/github/languages/code-size/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar)
[![github/repo-size](https://shields.io/github/repo-size/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar)
[![github/v](https://shields.io/github/v/release/Freed-Wu/tmux-status-bar)](https://github.com/Freed-Wu/tmux-status-bar)

[![cpan/v](https://img.shields.io/cpan/v/term-tmux-statusbar)](https://metacpan.org/pod/Term::Tmux::StatusBar::README)

![screenshot](https://github.com/Freed-Wu/tmux-status-bar/assets/32936898/ecd6dd2e-fdbc-43fd-a245-a8b2df058202)

A **not out-of-box** but **more flexible and powerful** tmux plugin to
customize tmux status bar. The biggest difference between other similar plugins
is it doesn't provide any variables to control status bar like other plugins,
but provides some functions to `~/.config/tmux/tmux.conf` and make it
possible to cooperate with other tmux plugin, which let users to control tmux
by a more "tmux" method.

## Similar Projects

- [powerline](https://github.com/powerline/powerline): use
  `~/.config/powerline/config.json` to configure
- [tmux-powerline](https://github.com/erikw/tmux-powerline): use
  `.tmux-powerlinerc`, which is a bash script, to configure
- There are many [tmux themes](https://github.com/rothgar/awesome-tmux#themes),
  which provide some variables to allow user to customize separators, colors and
  some less attributions on `~/.config/tmux/tmux.conf` by tmux script.
- [Oh My Tmux!](https://github.com/gpakosz/.tmux): it is not a tmux plugin, it
  is a tmux configuration, which contains some variables to configure tmux status
  bar like tmux themes. It is too large and perhaps separate some functions of
  its code to many different tmux plugins can be better.

## Usage

`~/.config/tmux/tmux.conf`:

```tmux
# [XXX] can be ignored
set -g status-left "#{status-left,[[format;][fg_color,bg_color,text;][sep];]...}"
set -g status-right "#{status-right,[[format;][sep;][fg_color,bg_color,text];]...}"
set -g window-status-current-format "#{window-status-current-format-left,[format;][sep;]fg_color,bg_color,text;[sep]}"
# or
set -g window-status-current-format "#{window-status-current-format-right,[format;][sep;]fg_color,bg_color,text;[sep]}"
```

For example, in `~/.config/tmux/tmux.conf`:

```tmux
set -g status-left "#{status-left:%s;#fffafa,black,a;;%s ;blue,green,b;; %s ;red,colour04,c;}"
```

It will be translated to:

<!-- markdownlint-disable MD013 -->

```sh
$ tmux show -gqv status-left
#[fg=#fffafa,bg=black]a#[fg=black,bg=green]#[fg=blue]b #[fg=green,bg=colour04]#[fg=red] c #[fg=colour04,bg=default]
```

<!-- markdownlint-enable MD013 -->

and output:

![example](https://github.com/Freed-Wu/tmux-status-bar/assets/32936898/769a5926-c428-4156-89db-e10c9b64406d)

Yes, this plugin is not out-of-box. You must call this function by yourself. As
a reward, you have more freedom to control tmux status line. Let us see a more
complex example, how to get the right status line of the first screenshot. The
code is copied from [my dotfiles](https://github.com/Freed-Wu/Freed-Wu):

```tmux
set -g status-right \
"#{status-right:%s;\
white,colour04,#{prefix_highlight}#[bg=colour04];\
black,yellow,#{pomodoro_status};\
\
black,#9370db,\
#{?#{==:#{bitahub_status_gtx1080ti},},,1080ti #{bitahub_status_gtx1080ti}}\
#{?#{||:#{==:#{bitahub_status_rtx3090},},#{==:#{bitahub_status_gtx1080ti},}},,}\
#{?#{==:#{bitahub_status_rtx3090},},,3090 #{bitahub_status_rtx3090}};\
\
white,#b34a47,\
#{?#{||:#{==:#{battery_percentage},0%},#{==:#{battery_percentage},}},\
#{net_speed},#{battery_icon_status}#{battery_remain}\
#{battery_color_status_fg}#[bg=#b34a47]\
#{battery_icon_charge}#{battery_percentage}};\
\
black,#87ceeb,%F%H:%M%a}"
```

We can see there are 5 sections. `%s` strips the default around white spaces to
save length.

1. Display if prefix key is pressed. Provided by
   [tmux-prefix-highlight](https://github.com/tmux-plugins/tmux-prefix-highlight).
2. A pomodoro timer. Provided by
   [tmux-pomodoro-plus](https://github.com/olimorris/tmux-pomodoro-plus).
3. Display number of GPU servers of my laboratory. Provided by
   [my plugin](https://github.com/Freed-Wu/tmux-bitahub). It can be split to
   three parts:
   1. `#{?#{==:#{bitahub_status_gtx1080ti},},,1080ti #{bitahub_status_gtx1080ti}}`:
      if `#{bitahub_status_gtx1080ti}` get empty result, which means network is
      offline. We don't display `1080ti` to save length.
   2. `#{?#{||:#{==:#{bitahub_status_rtx3090},},#{==:#{bitahub_status_gtx1080ti},}},,}`:
      when only both `#{bitahub_status_gtx1080ti}` and
      `#{bitahub_status_rtx3090}` are not empty, a seperator will be displayed.
   3. Same as first part.
4. Display battery percentage and charge time or net speed. That is because for
   desktop, which doesn't have a battery. So we display battery information for
   the laptop and net speed for the desktop. The code is similar to above section.
   Provided by [tmux-net-speed](https://github.com/tmux-plugins/tmux-net-speed) and
   [tmux-battery](https://github.com/tmux-plugins/tmux-battery).
5. Display date and time.

## Motivations

I create this plugin for two purposes:

- This plugin don't attach any other plugin which display useful information. You
  can search it in [awesome-tmux](https://github.com/rothgar/awesome-tmux) and
  [tmux-plugins/list](https://github.com/tmux-plugins/list). In fact, some
  IDE-like tmux plugin attach many parts to display some information, which are
  not general -- other tmux plugin cannot use them! Imitate Unix philosophy,
  every tmux plugin should do one thing, and do best. This plugin just provides
  some functions to control tmux status bar. Display useful information? That are
  other plugin's jobs.
- This plugin use tmux script which is the language `~/.config/tmux/tmux.conf`
  uses to configure. I know `powerline`s python, `tmux-powerline`'s bash is
  more advanced language, However, tmux script is more easy to call other tmux
  plugins, which cannot be ignored.

BTW, at the first screenshot, 0, 1, 2, ... is displayed to `⓪` `①`, `②`, which
is done by [my another plugin](https://github.com/Freed-Wu/tmux-digit). Don't
forget one plugin do one thing. :smile: If you want to use similar style of
prompt/status bar for other programs (gdb, lftp, ...), Here is
[an incomplete list](https://github.com/gnu-octave/prompt#similar-projects).

## Install

### [tpm](https://github.com/tmux-plugins/tpm)

```tmux
set -g @plugin Freed-Wu/tmux-status-bar
run ~/.config/tmux/plugins/tpm/tpm
```

### [CPAN](https://metacpan.org/dist/Term::Tmux::StatusBar)

```sh
cpan tmux-status-bar
```

```tmux
run-shell tmux-status-bar
```
