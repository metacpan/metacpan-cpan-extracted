# NAME

Net::OpenStack::Swift - Perl Bindings for the OpenStack Object Storage API, known as Swift.

# SYNOPSIS

    use Net::OpenStack::Swift;

    my $sw = Net::OpenStack::Swift->new(
        auth_url       => 'https://auth-endpoint-url/v2.0',
        user           => 'userid',
        password       => 'password',
        tenant_name    => 'project_id',
        # region         => 'REGION', # prefered region
        # auth_version => '2.0',      # by default
        # agent_options => +{
        #    timeout    => 10,
        #    user_agent => "Furl::HTTP",
        #}  
    );

    my ($storage_url, $token) = $sw->get_auth();

    my ($headers, $containers) = $sw->get_account(url => $storage_url, token => $token);
    # or,  storage_url and token can be omitted.
    my ($headers, $containers) = $sw->get_account();

    # 1.0 auth
    my $sw = Net::OpenStack::Swift->new(
        auth_url       => 'https://auth-endpoint-url/1.0',

        user           => 'region:user-id',
        password       => 'secret-api-key',

        # or private, if you are under the private network.
        auth_version  => '1.0',
        tenant_name   => 'public',
    );

# DESCRIPTION

Perl Bindings for the OpenStack Object Storage API, known as Swift.

# METHODS

## new

Creates a client.

- auth\_url

    Required. The url of the authentication endpoint.

- user

    Required.

- password

    Required.

- tenant\_name

    Required.
    tenant name/project

- auth\_version

    Optional.
    default 2.0

- agent\_options | HashRef

    Optional.
    Http Client options

## get\_auth

Get storage url and auth token.

    my ($storage_url, $token) = $sw->get_auth();

response:

- storage\_url

    Endpoint URL

- token

    Auth Token

## get\_account

Show account details and list containers.

    my ($headers, $containers) = $sw->get_account(marker => 'hoge');

- maker

    Optional.

- end\_maker

    Optional.

- prefix

    Optional.

- limit

    Optional.

## head\_account

Show account metadata.

    my $headers = $sw->head_account();

## post\_account

Create, update, or delete account metadata.

## get\_container

Show container details and list objects.

    my ($headers, $containers) = $sw->get_container(container_name => 'container1');

## head\_container

Show container metadata.

    my $headers = $sw->head_container(container_name => 'container1');

## put\_container

Create container.

    my $headers = $sw->put_container(container_name => 'container1')

## post\_container

Create, update, or delete container metadata.

## delete\_container

Delete container.

    my $headers = $sw->delete_container(container_name => 'container1');

## get\_object

Get object content and metadata.

    open my $fh, ">>:raw", "hoge.jpeg" or die $!;
    my $etag = $sw->get_object(container_name => 'container_name1', object_name => 'masakystjpeg',
        write_file => $fh,
    );
    # or chunked
    open my $fh, ">>:raw", "hoge.jpeg" or die $!;
    my $etag = $sw->get_object(container_name => 'container1', object_name => 'hoge.jpeg',
        write_code => sub {
            my ($status, $message, $headers, $chunk) = @_;
            print $status;
            print length($chunk);
            print $fh $chunk;
    });

- container\_name
- object\_name
- write\_file: FileHandle

    the response content will be saved here instead of in the response object.

- write\_code: Code reference

    the response content will be called for each chunk of the response content.

## head\_object

Show object metadata.

    my $headers = $sw->head_object(container_name => 'container1', object_name => 'hoge.jpeg');

## put\_object

Create or replace object.

    my $file = 'hoge.jpeg';
    open my $fh, '<', "./$file" or die;
    my $headers = $sw->put_object(container_name => 'container1',
        object_name => 'hoge.jpeg', content => $fh, content_length => -s $file);

- content: Str|FileHandle
- content\_length: Int
- content\_type: Str

    Optional.
    default none

## post\_object

Create or update object metadata.

## delete\_object

Delete object.

    my $headers = $sw->delete_object(container_name => 'container1', object_name => 'hoge.jpeg');

# Command Line Tool

perl client for the Swift API. a command-line script (swift.pl).

setup openstack environments

    $ export OS_AUTH_VERSION='1.0' # default 2.0
    $ export OS_AUTH_URL='https://*******'
    $ export OS_TENANT_NAME='*******'
    $ export OS_USERNAME='*******'
    $ export OS_PASSWORD='************'

cli examples

    $ swift.pl put container1
    $ swift.pl put container1 hello.txt (upload file)
    $ swift.pl list
    $ swift.pl list container1
    $ swift.pl list container1/hello.txt
    $ swift.pl get container1/hello.txt > hello.txt (download file)
    $ swift.pl delete container1/hello.txt
    $ swift.pl delete container1
    $ swift.pl delete 'container1/*'  (require quoting!)
    $ swift.pl post static '{"X-Container-Read":".r:*"}'

multi cpu support (parallel downloads and uploads)

    $ swift.pl donwload 'container1/*' (require quoting!)
    $ swift.pl upload 'container1/*' (require quoting!)

creating a .swift.pl.conf file in the user's home directory

    $ cat .swift.pl.conf 
    timeout=200
    user_agent=perl Net::OpenStack::Swift
    workers=8
    os_auth_url=
    os_tenant_name=
    os_username=
    os_password=

# Debug

To print request/response Debug messages, $ENV{LM\_DEBUG} must be true.

example

    $ LM_DEBUG=1 carton exec perl test.pl

# SEE ALSO

http://docs.openstack.org/developer/swift/

http://docs.openstack.org/developer/keystone/

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

masakyst <masakyst.public@gmail.com>
