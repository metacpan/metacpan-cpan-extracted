# NAME

Reply::Plugin::ORM - Reply + O/R Mapper

# SYNOPSIS

    ; .replyrc
    ...
    [ORM]
    config = ~/.reply-plugin-orm
    otogiri_plugins = DeleteCascade      ; You can use O/R Mapper plugin (in this case, 'Otogiri::Plugin::DeleteCascade'). 
    teng_plugins    = Count,SearchJoined ; You can use multiple plugins, like this.

    ; .reply-plugin-orm
    +{
        sandbox => {
            orm          => 'Otogiri', # or 'Teng'
            connect_info => ["dbi:SQLite:dbname=...", '', '', { ... }],
        }
    }
    
    $ PERL_REPLY_PLUGIN_ORM=sandbox reply

# DESCRIPTION

Reply::Plugin::ORM is Reply's plugin for operation of database using O/R Mapper.
In this version, we have support for Otogiri and Teng.

# METHODS

Using this module, you can use O/R Mapper's method at Reply shell.
If you set loading of O/R Mapper's plugin in config file, you can use method that provided by plugin on shell.

In order to prevent the redefined of function, these method's initials are upper case. 
You can call Teng's `single` method, like this: 

    1> Single 'table_name';

In addition, this module provides two additional methods.

- `Show_methods`

    This method outputs a list of methods provided by this module.

- `Show_dbname`

    This method outputs the name of database which you are connecting.

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>

# SEE ALSO

[Reply](https://metacpan.org/pod/Reply)

[Otogiri](https://metacpan.org/pod/Otogiri)

[Teng](https://metacpan.org/pod/Teng)
