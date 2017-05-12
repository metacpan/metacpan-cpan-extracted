# NAME

Parse::Crontab - Perl extension to parse Vixie crontab file

# SYNOPSIS

    use Parse::Crontab;
    my $crontab = Parse::Crontab->new(file => 'crontab.txt');
    unless ($crontab->is_valid) {
        warn $crontab->error_messages;
    }
    for my $job ($crontab->jobs) {
        say $job->minute;
        say $job->hour;
        say $job->day;
        say $job->month;
        say $job->day_of_week;
        say $job->command;
    }

# DESCRIPTION

This software is for parsing and validating Vixie crontab files.

# INTERFACE

## Constructor Options

### `file`

crontab file.

### `verbose`

verbose option (Default: 1).
If errors/warnings exist, errors/warnings message is dumped immediately when parsing.

### `has_user_field`

for the crontab format having user field (system-width cron files and all that).

## Functions

### `is_valid()`

Checking crontab is valid or not.

### `entries()`

returns all entries in crontab

### `jobs()`

returns job entries in crontab

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2013, Masayuki Matsuki. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
