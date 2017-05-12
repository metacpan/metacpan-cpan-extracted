# NAME

Script::Ichigeki - Perl extension for one time script.

# VERSION

This document describes Script::Ichigeki version 0.04.

# SYNOPSIS

    use Script::Ichigeki;

It is same as

    use Script::Ichigeki (
        exec_date       => 'XXXX-XX-XX', # today
        confirm_dialog  => 1,
        dialog_message  => 'Do you really execute `%s` ?',
    );

or

    use Script::Ichigeki ();
    Script::Ichigeki->hissatsu(
        exec_date       => 'XXXX-XX-XX', # today
        confirm_dialog  => 1,
        dialog_message  => 'Do you really execute `%s` ?',
    );

# DESCRIPTION

Script::Ichigeki is the module for one time script for mission critical
(especially for preventing rerunning it).

Only describing \`use Script::Ichigeki\`, confirm dialog is displayed and execution result
is saved in log file automatically. This log file double with lock file for mutual exclusion
and preventing rerunning.

# CAUTION

THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.

If forking in your script, the software may not be properly handling it.

# INTERFACE

## Functions

### `hissatsu(%options)`

Automatically called in use phase.

Available options are:

#### `exec_date => 'Str|Time::Piece'`

Date for execution date. Format is '%Y-%m-%d'.

#### `confirm_dialog => 'Bool'`

Confirm dialog is to be displayed or not.
default: 1

#### `dialog_message => 'Str'`

Message of confirm dialog.
Script name is expanded to '%s'.
If using multibyte strings, you should `$ use utf8;` before `$ use Script::Ichigeki`.
default: 'Do you really execute \`%s\` ?',

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](http://search.cpan.org/perldoc?perl)

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
