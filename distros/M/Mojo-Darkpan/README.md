# NAME

Mojo::Darkpan - A Mojolicious web service frontend leveraging OrePAN2

# DESCRIPTION

Mojo::Darkpan is a webservice build on Mojolicious to frontend [OrePAN2](https://metacpan.org/pod/OrePAN2). This module was inspired
by [OrePAN2::Server](https://metacpan.org/pod/OrePAN2::Server&#x27;) but built on 
Mojolicious to take advantage of it's robust framework of tools. A good bit of the documentation
was also taken from OrePAN2::Server as the functionality is similar if not identical.

# SYNOPSIS

## Running the server

    # start a server with default configurations on port 8080
    darkpan --port 8080
    
    # start a server with AD backed basic auth
    # config.json
    {
      "basic_auth": {
        "Realm Name": {
          "host": "ldaps://my.ldap.server.org",
          "port": 636,
          "basedn": "DC=my,DC=compoany,DC=org",
          "binddn": "bind_name",
          "bindpw": "bond_pw",
          "filter": "(&(objectCategory=*)(sAMAccountName=%s)(|(objectClass=user)(objectClass=group)))"
        }
      }
    }
    
    darkpan --config ./config.json

#### Options:

- **-c,--config** _default: undef_: 
    JSON configuration file location
- **-p,--port** _default: 3000_: 
    Web application port

## Configuring the server

Configurations can be done using environment variables or by creating a json config file.

### environment variables

Environment variables are at a higher order than values set in the json configuration 
file and will take precedence if set. The **DARKPAN\_CONFIG\_FILE** env variable can be 
set instead of using the command line option to denote the path of the config file.

- **DARKPAN\_CONFIG\_FILE**: 
    Location of a json configuration file, same as passing the --config option
- **DARKPAN\_DIRECTORY**:
     Directory where uploads will be stored.
- **DARKPAN\_PATH**:
    URL path to function as cpan repository resolver/mirror endpoint.
- **DARKPAN\_COMPRESS\_INDEX**:
    Setting whether to compress (gzip) the 02packages.details.txt file.
- **DARKPAN\_AUTH\_REALM**:
    Basic auth realm name. This variable needs to be set to enable parsing of additional
    auth settings using the following the format DARKPAN\_AUTH\_\[setting\].
- **DARKPAN\_AUTH\_\[setting\]**:
    Additional basic auth settings can be passed using this format. The settings
    will be parsed and applied to your basic auth configurations. See
    [Mojolicious::Plugin::BasicAuthPlus](https://metacpan.org/pod/Mojolicious::Plugin::BasicAuthPlus) 
    for additional details on configurations.

### config.json

The config.json file contains customizations for the darkpan web application. It can be
referenced by absolute path or relative to where the application is run from.

    {
      "directory": "darkpan",
      "compress_index": true,
      "path": "darkpan,
      "basic_auth": {
        "Realm Name": {
          "host": "ldaps://my.ldap.server.org",
          "port": 636,
          "basedn": "DC=my,DC=compoany,DC=org",
          "binddn": "bind_name",
          "bindpw": "bond_pw",
          "filter": "(&(objectCategory=*)(sAMAccountName=%s)(|(objectClass=user)(objectClass=group)))"
        }
      }
    }

#### config.json options

- **directory** _default: darkpan_: 
    Directory where uploads will be stored.
- **path** _default: darkpan_: 
    URL path to function as cpan repository resolver/mirror endpoint.
- **compress\_index** _default: true_: 
    Setting whether to compress (gzip) the 02packages.details.txt file.
- **basic\_auth** _default: undef_: 
    Basic authentication settings, see configurations for [Mojolicious::Plugin::BasicAuthPlus](https://metacpan.org/pod/Mojolicious::Plugin::BasicAuthPlus). When not provided
    no authentication is necessary to post modules to the service.

### Authentication

Authentication is handled by [Mojolicious::Plugin::BasicAuthPlus](https://metacpan.org/pod/Mojolicious::Plugin::BasicAuthPlus).
To configure basic auth, see the configuration options for [Mojolicious::Plugin::BasicAuthPlus](https://metacpan.org/pod/Mojolicious::Plugin::BasicAuthPlus)
and add your settings to the basic auth section of the config.json file.     

## How to Deploy 

### Deploying with POST

Publishing to darkpan can be done using a post request and a URL to git or bitbucket repo.

    #upload git managed module to my darkpan by curl 
    curl --data-urlencode 'module=git+ssh://git@mygit/home/git/repos/MyModule.git' --data-urlencode 'author=SHINGLER' http://localhost:3000/publish
    curl --data-urlencode 'module=git+file:///home/rshingleton/project/MyModule.git' --data-urlencode 'author=SHINGLER' http://localhost:3000/publish
    curl --data-urlencode 'module=git@github.com:rshingleton/perl-module-test.git' --data-urlencode 'author=SHINGLER' http://localhost:3000/publish

The module parameter can also be an HTTP url. see [OrePAN2::Injector](https://metacpan.org/pod/OrePAN2::Injector) for 
additional details.

    curl --data-urlencode 'module=https://cpan.metacpan.org/authors/id/O/OA/OALDERS/OrePAN2-0.48.tar.gz' --data-urlencode 'author=OALDERS' http://localhost:3000/publish
    

### Deploying with [Minilla](https://metacpan.org/pod/Minilla)

Minilla is a cpan authoring tool, see [Minilla](https://metacpan.org/pod/Minilla) for more details.

#### minil.toml

Add a reference to a pause configruation file in your minil.toml that points to your darkpan instance. 
The configuration can reference a relative path as follows:

    [release]
    pause_config=".pause"

#### .pause file

The .pause file is a configuration file for uploading modules to CPAN or your own Darkpan Repository.
See [CPAN::Uploader](https://metacpan.org/pod/CPAN::Uploader) for more detail.

    upload_uri http://my-darkpan.server/publish
    user myUsername
    password myPassword
    

_\*\* if you don't set the upload\_uri, you will upload to CPAN_

If basic auth is enabled, the username and password set in the .pause file will be
used as basic auth credentials.

## How to install from your Darkpan

### cpanm

See [cpanm](https://metacpan.org/pod/cpanm) for additional details.

     # check CPAN and your Darkpan server
     cpanm --mirror http://my-darkpan.server/darkpan
     
     # check for packages from only your Darkpan server
     cpanm --mirror-only http://my-darkpan.server/darkpan
     cpanm --from http://my-darkpan.server/darkpan

### cpm

See [cpm](https://metacpan.org/dist/App-cpm/view/script/cpm) for additional details.

    # resolve distribution names from DARKPAN/modules/02packages.details.txt.gz
    # and fetch distibutions from DARKPAN/authors/id/...
    > cpm install --resolver 02packages,http://example.com/darkpan Your::Module
    
    # use darkpan first, and if it fails, use metadb and normal CPAN
    > cpm install --resolver 02packages,http://my-darkpan.server/darkpan --resolver metadb Your::Module

### carton

See [carton](https://metacpan.org/pod/Carton) for additional details.

    # in the cpanfile
    # local mirror (darkpan)
    
    requires 'Plack', '== 0.9981',
      dist => 'MYCOMPANY/Plack-0.9981-p1.tar.gz',
      mirror => 'http://my-darkpan.server/darkpan';

Carton also uses an ([undocumented](https://domm.plix.at/perl/2017_07_carton_darkpan.html)) environment variable PERL\_CARTON\_MIRROR that will enable you
to add your Darkpan server to its list of resolvers. Carton will install from 
your Darkpan and from the default CPAN mirror.   

    PERL_CARTON_MIRROR=http://my-darkpan.server/darkpan carton install  

# SEE ALSO

[OrePAN2](https://metacpan.org/pod/OrePAN2)

[OrePAN2::Server](https://metacpan.org/pod/OrePAN2::Server)

# LICENSE

Copyright (C) rshingleton.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

rshingleton <reshingleton@gmail.com>
