# NAME

Reply::Plugin::ConfigurablePrompt - Configurable prompt for reply

# SYNOPSIS

    ; in your .replyrc use following instead of [FancyPrompt] (or other prompt plugin)
    [ConfigurablePrompt]
    prompt="reply $history_count \$ "

# DESCRIPTION

Reply::Plugin::ConfigurablePrompt is plugin for Reply. This plugin provides configurable prompt.

# NOTE

This plugin is exclusive to other prompt plugin.

# HOW TO CUSTOMIZE

You can use any perl syntax in prompt section. variables and functions are usable if these are exported in main package.

# EXPORTED VARIABLES

## $history\_count

the history number of this command

# LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takuya Tsuchida <tsucchi@cpan.org>
