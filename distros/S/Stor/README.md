[![Build Status](https://travis-ci.org/avast/Stor.svg?branch=master)](https://travis-ci.org/avast/Stor)
# NAME

Stor - Save/retrieve a file to/from primary storage

# SYNOPSIS

    # retrieve a file
    curl http://stor-url/946a5ec1d49e0d7825489b1258476fdd66a3e9370cc406c2981a4dc3cd7f4e4f

    # store a file
    curl -X POST --data-binary @my_file http://user:pass@stor-url/946a5ec1d49e0d7825489b1258476fdd66a3e9370cc406c2981a4dc3cd7f4e4f

# DESCRIPTION

Stor is an HTTP API to primary storage. You provide a SHA256 hash and get the file contents, or you provide a SHA256 hash and a file contents and it gets stored to primary storages.

## How to use?

### docker way

    docker run -v $PWD/config.json.example:/etc/stor.conf -e CONFIG_FILE=/etc/stor.conf avastsoftware/stor:TAG

### perl way (development)

    #local install dependency
    carton install

    #run
    CONFIG_FILE=config.json.example carton exec perl -Ilib script/stor

### perl way (production)

we prefer [hypnotoad](https://mojolicious.org/perldoc/Mojo/Server/Hypnotoad) server

## configuration

- rabbitmq\_uri

    (optional)

    if is set, then requested SHA are published to exchange (defined by URI - https://www.rabbitmq.com/uri-spec.html)

### configuration example

    {
        "statsite": {
            "host": "STATSITE_HOST",
            "prefix": "stor.dev",
            "sample_rate": 0.1
        },
        "storage_pairs": [
            ["/mnt/data1", "/mnt/data2"],
            ["/mnt/data3", "/mnt/data4"]
        ],
        "writable_pairs_regex": "data[12]",
        "s3_enabled" : true,
        "s3_credentials" : {
            "access_key" : "S3_ACCESS_KEY",
            "secret_key" : "S3_SECRET_KEY",
            "host" : "S3_HOST"
        },
        "memcached_servers": ["MEMCACHED_SERVER1"],
        "secret": "https://mojolicious.org/perldoc/Mojolicious/Guides/FAQ#What-does-Your-secret-passphrase-needs-to-be-changed-mean",
        "basic_auth": "writer:writer_pass",
        "rabbitmq_uri": "amqp://"
    }

## Service Responsibility

- provide HTTP API
- redundancy support
- resource allocation

## API

### HEAD /:sha

#### 200 OK

File exists

Headers:

    Content-Length - file size of file
    Last-Modified - last modification time

#### 404 Not Found

Sample not found

### GET /:sha

#### 200 OK

File exists

Headers:

    Content-Length - file size of file
    Last-Modified - last modification time

GET return content of file in body

#### 404 Not Found

Sample not found

### POST /:sha

save sample to n-tuple of storages

For authentication use Basic access authentication

compare SHA and sha256 of file

#### 200 OK

file exists

#### 201 Created

file was added to all storages

#### 401 Unauthorized

Bad authentication

#### 412 Precondition Failed

content mismatch - sha256 of content not equal SHA

#### 507 Insufficient Storage

There is not enough space on storage to save the file.

### GET /status

#### 200 OK

all storages are available

#### 503

some storage is unavailable

## Resource Allocation

save samples to n-tuple of storages with enough of resources => service responsibility is check disk usage

nice to have is balanced samples to all storages equally

# LICENSE

Copyright (C) Avast Software

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Miroslav Tynovsky <tynovsky@avast.com>
