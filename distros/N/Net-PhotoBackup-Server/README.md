# PhotoBackup Perl server

The Perl implementation of PhotoBackup server. It provides a server and startup script
for [PhotoBackup](https://photobackup.github.io/) Android app. It was developed by
reading the [API docs](https://github.com/PhotoBackup/api/blob/master/api.raml)
and looking at the sourcecode of the
[bottle](https://github.com/PhotoBackup/server-bottle) and
[flask](https://github.com/PhotoBackup/server-flask) python implementations.


## Usage

    # Initial setup of server config.
    photobackup.pl init

    # Launch server using config.
    photobackup.pl run

## Description

### new()

    Constructor.

    Any args will be added to $self, overriding any defaults.

### init()

    Create, or recreate the user's config file.

    The user will be prompted for the following information:

    Media root - Directory where the pictures will be stored.

    Server password - The password to use for all HTTP operations.

    Server port - Defaults to 8420.

    Some rudimentary checking will be done for valid input.

### config()

    Read and write server config file.

    Returns undef if config file doesn't exist, or doesn't hold all required
    data.

    The config will be written to ~/.photobackup in INI format.

    I'm reading and writing this simple INI file manually rather than using a
    CPAN module so as to reduce the dependencies.

### run()

Launch the PhotoBackup web service using config from the conf file.

### stop()

Kill any running PhotoBackup web service.

### app()

Return the PSGI application subref.

## License

Copyright (C) 2015 Dave Webb.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

## Author

Dave Webb <github@d5ve.com>
