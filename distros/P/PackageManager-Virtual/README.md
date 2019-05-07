# SYNOPSIS

    if ( $obj->does('PackageManager::Virtual') ) {

        # Installs a package named 'cool_app'
        $obj->install( name => 'cool_app' );

        # Removes a package named 'app1'. Output is verbose.
        $obj->remove( verbose => 1, name => 'app1' );

        # Prints all installed packages
        print "\'$_->{name}\' has version \'$_->{version}\'\n"
            foreach ( $obj->list() );
    }

# DESCRIPTION

A moose role that exposes functionalities for software package management.

## METHODS

### list( \[verbose => BOOLEAN\] )

Gets all installed packages.

The returned value is an array; every index is a hashref with the following
key-value pairs:

- **name**    => STRING

    _The name of the package._

- **version** => STRING

    _A specific version of the package._

#### verbose

When this parameters value is "**1**" this command may output additional
information to STDOUT.

### install( name => STRING, \[version => STRING, verbose => BOOLEAN\] )

Installs a specified package.

The returned value is an integer. The value "**0**" implies a successful
installation. Otherwise, it indicates there was an error and the package was
not installed.

#### name

The name of the package to be installed.

#### version

The version of the package to be installed. If omitted, the package version
is automatically selected.

#### verbose

When this parameters value is "**1**" this command may output additional
information to STDOUT.

### remove( name => STRING, \[verbose => BOOLEAN\] )

Removes a specified package.

The returned value is an integer. The value "**0**" implies a successful
removal. Otherwise, it indicates there was an error in the removal process and
the package was not removed.

#### name

The name of the package to be removed.

#### verbose

When this parameters value is "**1**" this command may output additional
information to STDOUT.
