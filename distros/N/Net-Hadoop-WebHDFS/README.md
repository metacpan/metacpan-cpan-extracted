# NAME

Net::Hadoop::WebHDFS - Client library for Hadoop WebHDFS and HttpFs

# SYNOPSIS

    use Net::Hadoop::WebHDFS;
    my $client = Net::Hadoop::WebHDFS->new( host => 'hostname.local', port => 50070 );

    my $statusArrayRef = $client->list('/');

    my $contentData = $client->read('/data.txt');

    $client->create('/foo/bar/data.bin', $bindata);

# DESCRIPTION

This module supports WebHDFS v1 on Hadoop 1.x (and CDH4.0.0 or later), and HttpFs on Hadoop 2.x (and CDH4 or later).
WebHDFS/HttpFs has two authentication methods: pseudo authentication and Kerberos, but this module supports pseudo authentication only.

# METHODS

Net::Hadoop::WebHDFS class method and instance methods.

## CLASS METHODS

### `Net::Hadoop::WebHDFS->new( %args ) :Net::Hadoop::WebHDFS`

Creates and returns a new client instance with _%args_.
If you are using HttpFs, set _httpfs\_mode => 1_ and _port => 14000_.

_%args_ might be:

- host :Str = "namenode.local"
- port :Int = 50070
- standby\_host :Str = "standby.namenode.local"
- standby\_port :Int = 50070
- username :Str = "hadoop"
- doas :Str = "hdfs"
- httpfs\_mode :Bool = 0/1

## INSTANCE METHODS

### `$client->create($path, $body, %options) :Bool`

Creates file on HDFS with _$body_ data. If you want to create blank file, pass blank string.

_%options_ might be:

- overwrite :Str = "true" or "false"
- blocksize :Int
- replication :Int
- permission :Str = "0600"
- buffersize :Int

### `$client->append($path, $body, %options) :Bool`

Append _$body_ data to _$path_ file.

_%options_ might be:

- buffersize :Int

### `$client->read($path, %options) :Str`

Open file of _$path_ and returns its content. Alias: **open**.

_%options_ might be:

- offset :Int
- length :Int
- buffersize :Int

### `$client->mkdir($path, [permission => '0644']) :Bool`

Make directory _$path_ on HDFS. Alias: **mkdirs**.

### `$client->rename($path, $dest) :Bool`

Rename file or directory as _$dest_.

### `$client->delete($path, [recursive => 0/1]) :Bool`

Delete file _$path_ from HDFS. With optional _recursive => 1_, files and directories are removed recursively (default false).

### `$client->stat($path) :HashRef`

Get and returns file status object for _$path_. Alias: **getfilestatus**.

### `$client->list($path) :ArrayRef`

Get list of files in directory _$path_, and returns these status objects arrayref. Alias: **liststatus**.

### `$client->content_summary($path) :HashRef`

Get 'content summary' object and returns it. Alias: **getcontentsummary**.

### `$client->checksum($path) :HashRef`

Get checksum information object for _$path_. Alias: **getfilechecksum**.

### `$client->homedir() :Str`

Get accessing user's home directory path. Alias: **gethomedirectory**.

### `$client->chmod($path, $mode) :Bool`

Set permission of _$path_ as octal _$mode_. Alias: **setpermission**.

### `$client->chown($path, [owner => 'username', group => 'groupname']) :Bool`

Set owner or group of _$path_. One of owner/group must be specified. Alias: **setowner**.

### `$client->replication($path, $replnum) :Bool`

Set replica number for _$path_. Alias: **setreplication**.

### `$client->touch($path, [modificationtime => $mtime, accesstime => $atime]) :Bool`

Set mtime/atime of _$path_. Alias: **settimes**.

### `$client->touchz($path) :Bool`

Create a zero length file.

### `$client->checkaccess( $path, $fsaction ) :Bool`

Test if the user has the rights to do a file system action.

### `$client->concat( $path, @source_paths ) :Bool`

Concatenate paths.

### `$client->truncate( $path, $newlength ) :Bool`

Truncate a path contents.

### `$client->delegation_token( $action, $path, @args )`

This is a method wrapping the multiple methods for delegation token
handling.

    my $token = $client->delegation_token( get => $path );
    print "Token: $token\n";

    my $milisec = $client->delegation_token( renew => $token );
    printf "Token expiration renewed until %s\n", scalar localtime $milisec / 1000;

    if ( $client->delegation_token( cancel => $token ) ) {
        print "Token cancelled. There will be a new one created.\n";
        my $token_new = $client->delegation_token( get => $path );
        print "New token: $token_new\n";
        printf "New token is %s\n", $token_new eq $token ? 'the same' : 'different';
    }
    else {
        warn "Failed to cancel token $token!";
    }

#### `$client->delegation_token( get => $path, [renewer => $username, service => $service, kind => $kind ] ) :Str )`

Returns the delegation token id for the specified path.

#### `$client->delegation_token( renew => $token ) :Int`

Returns the new expiration time for the specified delegation token in miliseconds.

#### `$client->delegation_token( cancel => $token ) :Bool`

Cancels the specified delegation token (which will force a new one to be created.

### `$client->snapshot( $path, $action => @args )`

This is a method wrapping the multiple methods for snapshot handling.

#### `$client->snapshot( $path, create => [, $snapshotname ] ) :Str`

Creates a new snaphot on the specified path and returns the name of the
snapshot.

#### `$client->snapshot( $path, rename => $oldsnapshotname, $snapshotname ) :Bool`

Renames the snaphot.

#### `$client->snapshot( $path, delete => $snapshotname ) :Bool`

Deletes the specified snapshot.

### `$client->xattr( $path, $action, @args )`

This is a method wrapping the multiple methods for extended attributes handling.

    my @attr_names = $client->xattr( $path, 'list' );

    my %attr = $client->xattr( $path, get => flatten => 1 );

    if ( ! exists $attr{'user.bar'} ) {
        warn "set user.bar = 42\n";
        $client->xattr( $path, create => 'user.bar' => 42 )
            || warn "Failed to create user.bar";
    }
    else {
        warn "alter user.bar = 24\n";
        $client->xattr( $path, replace => 'user.bar' => 24 )
            || warn "Failed to replace user.bar";
        ;
    }

    if ( exists $attr{'user.foo'} ) {
        warn "No more foo\n";
        $client->xattr( $path, remove => 'user.foo')
            || warn "Failed to remove user.foo";
        ;
    }

#### `$client->xattr( $path, get => [, names => \@attr_names]  [, flatten => 1 ] [, encoding => $enc ] ) :Struct`

Returns the extended attribute key/value pairs on a path. The default data set
is an array of hashrefs with the pairs, however if you set `<flatten`> to a true
value then a simple hash will be returned.

It is also possible to fetch a subset of the attributes if you specify the
names of them with the `<names`> option.

#### `$client->xattr( $path, 'list' ) :List`

This method will return the names of all the attributes set on `<$path`>.

#### `$client->xattr( $path, create => $attr_name => $value ) :Bool`

It is possible to create a new  extended attribute on a path with this method.

#### `$client->xattr( $path, replace => $attr_name => $value ) :Bool`

It is possible to replace the value of an existing extended attribute on a path
with this method.

#### `$client->xattr( $path, remove => $attr_name ) :Bool`

Deletes the speficied attribute on `<$path`>.

## EXTENSIONS

### `$client->exists($path) :Bool`

Returns the `stat()` hash if successful, and false otherwise. Dies on
interface errors.

### `$client->find($path, $callback, $options_hash)`

Loops recursively over the specified path:

    $client->find(
        '/user',
        sub {
            my($cwd, $path) = @_;
            my $date = localtime $path->{modificationTime};
            my $type = $path->{type} eq q{DIRECTORY} ? "[dir ]" : "[file]";
            my $size = sprintf "% 10s",
                                $path->{blockSize}
                                    ? sprintf "%.2f MB", $path->{blockSize} / 1024**2
                                    : 0;
            print "$type $size $path->{permission} $path->{owner}:$path->{group} $cwd/$path->{pathSuffix}\n";
        },
        { # optional
            re_ignore => qr{
                            \A      # Filter some filenames out even before reaching the callback
                                [_] # logs and meta data, java junk, _SUCCESS files, etc.
                        }xms,
        }
    );

# AUTHOR

TAGOMORI Satoshi &lt;tagomoris {at} gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
