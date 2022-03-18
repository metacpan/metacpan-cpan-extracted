# NAME

Net::Async::WebService::lxd - REST client (asynchronous) for lxd Linux containers

# SYNOPSIS

    use IO::Async::Loop;
    my $loop = IO::Async::Loop->new;

    use Net::Async::WebService::lxd;
    my $lxd = Net::Async::WebService::lxd->new( loop            => $loop,
                                                endpoint        => 'https://192.168.0.50:8443',
                                                SSL_cert_file   => "t/client.crt",
                                                SSL_key_file    => "t/client.key",
                                                SSL_fingerprint => 'sha1$92:DD:63:F8:99:C4:5F:82:59:52:82:A9:09:C8:57:F0:67:56:B0:1B',
                                                );
    $lxd->create_instance(
             body => {
                 architecture => 'x86_64',
                 profiles     => [ 'default'  ],
                 name         => 'test1',
                 source       => { type        => 'image',
                                   fingerprint => '6dc6aa7c8c00' },  # image already exists in image store
                 config       => {},
             } )->get;                                               # wait for it
    # container is still stopped
    $lxd->instance_state( name => 'test1',
             body => {
                 action   => "start",
                 force    => JSON::false,
                 stateful => JSON::false,
                 timeout  => 30,
             } )->get;                                               # wait for it

# INTERFACE

## Constructor

The constructor returns a handle to one LXD server. It's address is specified via an **endpoint**
parameter, be it of an HTTPS or of a UNIX socket kind.

If you are working with a non-default LXD project in mind, then you should also provide that
project's name with the **project** parameter. Background operation polling will make use of
that. Note, that when invoking any of the methods here, you will still have to specify that project,
unless it is the `default` one, of course.

As we are operating under an [IO::Async](https://metacpan.org/pod/IO::Async) regime here, the handle also needs a **loop** parameter to
the central event loop. The handle will also regularily poll autonomously the server which
operations are still running or have completed. The optional parameter **polling\_time** controls how
often that will occur; it will default to 1 sec, if not provided.

As LXC can be accessed remotely only via HTTPS, TLS (SSL) parameters must be provided. These will be
forwarded directly to
[IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL#Description-Of-Methods). But, specifically,
one should consider to provide:

- **client certificate**, via a proper subset of `SSL_cert_file`, `SSL_key_file`, `SSL_cert` and `SSL_key`.
(Look at the ["HINTS"](#hints) section to generate such a certificate for LXD.)
- **server fingerprint**, via `SSL_fingerprint`
(Look at the ["HINTS"](#hints) section how to figure this out.)

## Methods

All methods below are automatically generated from the [LXD REST API Spec](https://raw.githubusercontent.com/lxc/lxd/master/doc/rest-api.yaml).
They should work with API version 1.0.

Let's dissect method invocations with this example:

    my $f = $lxd->instance_state( name => 'test1' );
    my $r = $f->get;

- All invocations return a [Future](https://metacpan.org/pod/Future). Thus they can be combined, sequenced, run in "parallel", etc. If
you need to wait for a definite result, then you will block the flow with `->get`.

    Polling is done behind the scenes and will watch for all operations which either succeeded or
    failed. Those will mark the associated future as `done` or `failed`. Normally, you will never need
    to use the methods for 'Operations' yourself; they are still offered as fallback.

- The result of each fully completed invocation is either
    - the string `success`, or
    - a Perl HASH ref which reflects the JSON data sent from the LXD server. Note, that Booleans have to
    be treated special, by using `JSON::false` and `JSON::true`. Otherwise, they follow **exactly** the
    structure in the specification.
    - or a HASH ref with keys `stdin` and `stdout` if this is a result of the `execute_in_instance`
    method.
- If an operation failed, then the associated future will be failed, together with the reason of the
failure from the server. If you do not cater with that, then this will - as usual with `IO::Async`
- raise an exception, with the failure as string.
- Methods named like the type of server object (e.g. `cluster`, `certificate`, `image`) are
normally "getter/setter" methods. The getter obviously returns the state of the object. The method
becomes a setter, if the additional `body` field together with a Perl HASH ref is passed:

        my $f = $lxd->instance_state( name => 'test1',
                                      body => {
                                        action   => "start",
                                        force    => JSON::false,
                                        stateful => JSON::false,
                                        timeout  => 30,
                                      } );

    How a specific object is addressed, is detailed in each method below; usually you provide a `name`,
    `id`, `fingerprint`, or similar. You may also have to provide a `project`, if not being the
    _default project_.

    That HASH ref also follows the structure outlined in the specification for that particular endpoint.

- Methods named like a type of server object (e.g. `certificates`) normally return a list of
identifiers for such objects.
- Many methods request changes in the LXD server. The names are taken from the specification, but are
adapted to better reflect what is intended:
    - Methods which change the state of the remote object usually are called `modify`\__something_.
    - Methods which add a new object to a collection are usually called `add`\__something_, or
    `create`\__something_, depending on how it sounds better.
    - Methods which remove an object from a collection are usually called `delete`\__something_.

## Certificates

- **add\_certificate**

    Adds a certificate to the trust store.
    In this mode, the \`password\` property is always ignored.

    - `body`: certificate, required

            description: CertificatesPost represents the fields of a new LXD certificate
            properties:
              certificate:
                description: 'The certificate itself, as PEM encoded X509'
                example: X509 PEM certificate
                type: string
              name:
                description: Name associated with the certificate
                example: castiana
                type: string
              password:
                description: Server trust password (used to add an untrusted client)
                example: blah
                type: string
              projects:
                description: List of allowed projects (applies when restricted)
                example:
                  - default
                  - foo
                  - bar
                items:
                  type: string
                type: array
              restricted:
                description: Whether to limit the certificate to listed projects
                example: true
                type: boolean
              token:
                description: Whether to create a certificate add token
                example: true
                type: boolean
              type:
                description: Usage type for the certificate (only client currently)
                example: client
                type: string
            type: object

- **add\_certificate\_untrusted**

    Adds a certificate to the trust store as an untrusted user.
    In this mode, the \`password\` property must be set to the correct value.

    The \`certificate\` field can be omitted in which case the TLS client
    certificate in use for the connection will be retrieved and added to the
    trust store.

    The \`?public\` part of the URL isn't required, it's simply used to
    separate the two behaviors of this endpoint.

    - `body`: certificate, required

            description: CertificatesPost represents the fields of a new LXD certificate
            properties:
              certificate:
                description: 'The certificate itself, as PEM encoded X509'
                example: X509 PEM certificate
                type: string
              name:
                description: Name associated with the certificate
                example: castiana
                type: string
              password:
                description: Server trust password (used to add an untrusted client)
                example: blah
                type: string
              projects:
                description: List of allowed projects (applies when restricted)
                example:
                  - default
                  - foo
                  - bar
                items:
                  type: string
                type: array
              restricted:
                description: Whether to limit the certificate to listed projects
                example: true
                type: boolean
              token:
                description: Whether to create a certificate add token
                example: true
                type: boolean
              type:
                description: Usage type for the certificate (only client currently)
                example: client
                type: string
            type: object

- **certificate**

    Gets a specific certificate entry from the trust store.

    Updates the entire certificate configuration.

    - `fingerprint`: string, required
    - `body`: certificate, required

            description: CertificatePut represents the modifiable fields of a LXD certificate
            properties:
              certificate:
                description: 'The certificate itself, as PEM encoded X509'
                example: X509 PEM certificate
                type: string
              name:
                description: Name associated with the certificate
                example: castiana
                type: string
              projects:
                description: List of allowed projects (applies when restricted)
                example:
                  - default
                  - foo
                  - bar
                items:
                  type: string
                type: array
              restricted:
                description: Whether to limit the certificate to listed projects
                example: true
                type: boolean
              type:
                description: Usage type for the certificate (only client currently)
                example: client
                type: string
            type: object

- **certificates**

    Returns a list of trusted certificates (URLs).

- **certificates\_recursion1**

    Returns a list of trusted certificates (structs).

- **delete\_certificate**

    Removes the certificate from the trust store.

    - `fingerprint`: string, required

- **modify\_certificate**

    Updates a subset of the certificate configuration.

    - `fingerprint`: string, required
    - `body`: certificate, required

            description: CertificatePut represents the modifiable fields of a LXD certificate
            properties:
              certificate:
                description: 'The certificate itself, as PEM encoded X509'
                example: X509 PEM certificate
                type: string
              name:
                description: Name associated with the certificate
                example: castiana
                type: string
              projects:
                description: List of allowed projects (applies when restricted)
                example:
                  - default
                  - foo
                  - bar
                items:
                  type: string
                type: array
              restricted:
                description: Whether to limit the certificate to listed projects
                example: true
                type: boolean
              type:
                description: Usage type for the certificate (only client currently)
                example: client
                type: string
            type: object

## Cluster

- **add\_cluster\_member**

    Requests a join token to add a cluster member.

    - `body`: cluster, required

            properties:
              server_name:
                description: The name of the new cluster member
                example: lxd02
                type: string
            title: ClusterMembersPost represents the fields required to request a join token to add a member to the cluster.
            type: object

- **cluster**

    Gets the current cluster configuration.

    Updates the entire cluster configuration.

    - `body`: cluster, required

            description: |-
              ClusterPut represents the fields required to bootstrap or join a LXD
              cluster.
            properties:
              cluster_address:
                description: The address of the cluster you wish to join
                example: 10.0.0.1:8443
                type: string
              cluster_certificate:
                description: The expected certificate (X509 PEM encoded) for the cluster
                example: X509 PEM certificate
                type: string
              cluster_password:
                description: The trust password of the cluster you're trying to join
                example: blah
                type: string
              enabled:
                description: Whether clustering is enabled
                example: true
                type: boolean
              member_config:
                description: List of member configuration keys (used during join)
                example: []
                items:
                  $ref: '#/definitions/ClusterMemberConfigKey'
                type: array
              server_address:
                description: The local address to use for cluster communication
                example: 10.0.0.2:8443
                type: string
              server_name:
                description: Name of the cluster member answering the request
                example: lxd01
                type: string
            type: object

- **cluster\_member**

    Gets a specific cluster member.

    Updates the entire cluster member configuration.

    - `name`: string, required
    - `body`: cluster, required

            description: ClusterMemberPut represents the the modifiable fields of a LXD cluster member
            properties:
              config:
                additionalProperties:
                  type: string
                description: Additional configuration information
                example:
                  scheduler.instance: all
                type: object
              description:
                description: Cluster member description
                example: AMD Epyc 32c/64t
                type: string
              failure_domain:
                description: Name of the failure domain for this cluster member
                example: rack1
                type: string
              groups:
                description: List of cluster groups this member belongs to
                example:
                  - group1
                  - group2
                items:
                  type: string
                type: array
              roles:
                description: List of roles held by this cluster member
                example:
                  - database
                items:
                  type: string
                type: array
            type: object

- **cluster\_members**

    Returns a list of cluster members (URLs).

- **cluster\_members\_recursion1**

    Returns a list of cluster members (structs).

- **clustering\_update\_cert**

    Replaces existing cluster certificate and reloads LXD on each cluster
    member.

    - `body`: cluster, required

            description: ClusterCertificatePut represents the certificate and key pair for all members in a LXD Cluster
            properties:
              cluster_certificate:
                description: The new certificate (X509 PEM encoded) for the cluster
                example: X509 PEM certificate
                type: string
              cluster_certificate_key:
                description: The new certificate key (X509 PEM encoded) for the cluster
                example: X509 PEM certificate key
                type: string
            type: object

- **create\_cluster\_group**

    Creates a new cluster group.

    - `body`: cluster, required

            properties:
              description:
                description: The description of the cluster group
                example: amd64 servers
                type: string
              members:
                description: List of members in this group
                example:
                  - node1
                  - node3
                items:
                  type: string
                type: array
              name:
                description: The new name of the cluster group
                example: group1
                type: string
            title: ClusterGroupsPost represents the fields available for a new cluster group.
            type: object

- **delete\_cluster\_member**

    Removes the member from the cluster.

    - `name`: string, required

- **modify\_cluster\_member**

    Updates a subset of the cluster member configuration.

    - `name`: string, required
    - `body`: cluster, required

            description: ClusterMemberPut represents the the modifiable fields of a LXD cluster member
            properties:
              config:
                additionalProperties:
                  type: string
                description: Additional configuration information
                example:
                  scheduler.instance: all
                type: object
              description:
                description: Cluster member description
                example: AMD Epyc 32c/64t
                type: string
              failure_domain:
                description: Name of the failure domain for this cluster member
                example: rack1
                type: string
              groups:
                description: List of cluster groups this member belongs to
                example:
                  - group1
                  - group2
                items:
                  type: string
                type: array
              roles:
                description: List of roles held by this cluster member
                example:
                  - database
                items:
                  type: string
                type: array
            type: object

- **rename\_cluster\_member**

    Renames an existing cluster member.

    - `name`: string, required
    - `body`: cluster, required

            properties:
              server_name:
                description: The new name of the cluster member
                example: lxd02
                type: string
            title: ClusterMemberPost represents the fields required to rename a LXD node.
            type: object

- **restore\_cluster\_member\_state**

    Evacuates or restores a cluster member.

    - `name`: string, required
    - `body`: cluster, required

            properties:
              action:
                description: The action to be performed. Valid actions are "evacuate" and "restore".
                example: evacuate
                type: string
            title: ClusterMemberStatePost represents the fields required to evacuate a cluster member.
            type: object

## Cluster Groups

- **cluster\_group**

    Gets a specific cluster group.

    Updates the entire cluster group configuration.

    - `name`: string, required
    - `body`: cluster group, required

            properties:
              description:
                description: The description of the cluster group
                example: amd64 servers
                type: string
              members:
                description: List of members in this group
                example:
                  - node1
                  - node3
                items:
                  type: string
                type: array
            title: ClusterGroupPut represents the modifiable fields of a cluster group.
            type: object

- **cluster\_groups**

    Returns a list of cluster groups (URLs).

- **cluster\_groups\_recursion1**

    Returns a list of cluster groups (structs).

- **delete\_cluster\_group**

    Removes the cluster group.

    - `name`: string, required

- **modify\_cluster\_group**

    Updates the cluster group configuration.

    - `name`: string, required
    - `body`: cluster group, required

            properties:
              description:
                description: The description of the cluster group
                example: amd64 servers
                type: string
              members:
                description: List of members in this group
                example:
                  - node1
                  - node3
                items:
                  type: string
                type: array
            title: ClusterGroupPut represents the modifiable fields of a cluster group.
            type: object

- **rename\_cluster\_group**

    Renames an existing cluster group.

    - `name`: string, required
    - `body`: name, required

            properties:
              name:
                description: The new name of the cluster group
                example: group1
                type: string
            title: ClusterGroupPost represents the fields required to rename a cluster group.
            type: object

## Images

- **add\_images\_alias**

    Creates a new image alias.

    - `project`: string, optional
    - `body`: image alias, required

            description: ImageAliasesPost represents a new LXD image alias
            properties:
              description:
                description: Alias description
                example: Our preferred Ubuntu image
                type: string
              name:
                description: Alias name
                example: ubuntu-20.04
                type: string
              target:
                description: Target fingerprint for the alias
                example: 06b86454720d36b20f94e31c6812e05ec51c1b568cf3a8abd273769d213394bb
                type: string
              type:
                description: Alias type (container or virtual-machine)
                example: container
                type: string
            type: object

- **create\_image**

    Adds a new image to the image store.

    - `project`: string, optional
    - `body`: image, optional

            description: ImagesPost represents the fields available for a new LXD image
            properties:
              aliases:
                description: Aliases to add to the image
                example:
                  - name: foo
                  - name: bar
                items:
                  $ref: '#/definitions/ImageAlias'
                type: array
              auto_update:
                description: Whether the image should auto-update when a new build is available
                example: true
                type: boolean
              compression_algorithm:
                description: Compression algorithm to use when turning an instance into an image
                example: gzip
                type: string
              expires_at:
                description: When the image becomes obsolete
                example: 2025-03-23T20:00:00-04:00
                format: date-time
                type: string
              filename:
                description: Original filename of the image
                example: lxd.tar.xz
                type: string
              profiles:
                description: List of profiles to use when creating from this image (if none provided by user)
                example:
                  - default
                items:
                  type: string
                type: array
              properties:
                additionalProperties:
                  type: string
                description: Descriptive properties
                example:
                  os: Ubuntu
                  release: focal
                  variant: cloud
                type: object
              public:
                description: Whether the image is available to unauthenticated users
                example: false
                type: boolean
              source:
                $ref: '#/definitions/ImagesPostSource'
            type: object

    - `body`: raw\_image, optionalsee Spec

- **delete\_image**

    Removes the image from the image store.

    - `fingerprint`: string, required
    - `project`: string, optional

- **delete\_image\_alias**

    Deletes a specific image alias.

    - `name`: string, required
    - `project`: string, optional

- **image**

    Gets a specific image.

    Updates the entire image definition.

    - `fingerprint`: string, required
    - `project`: string, optional
    - `body`: image, required

            description: ImagePut represents the modifiable fields of a LXD image
            properties:
              auto_update:
                description: Whether the image should auto-update when a new build is available
                example: true
                type: boolean
              expires_at:
                description: When the image becomes obsolete
                example: 2025-03-23T20:00:00-04:00
                format: date-time
                type: string
              profiles:
                description: List of profiles to use when creating from this image (if none provided by user)
                example:
                  - default
                items:
                  type: string
                type: array
              properties:
                additionalProperties:
                  type: string
                description: Descriptive properties
                example:
                  os: Ubuntu
                  release: focal
                  variant: cloud
                type: object
              public:
                description: Whether the image is available to unauthenticated users
                example: false
                type: boolean
            type: object

- **image\_alias**

    Gets a specific image alias.

    Updates the entire image alias configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: image alias, required

            description: ImageAliasesEntryPut represents the modifiable fields of a LXD image alias
            properties:
              description:
                description: Alias description
                example: Our preferred Ubuntu image
                type: string
              target:
                description: Target fingerprint for the alias
                example: 06b86454720d36b20f94e31c6812e05ec51c1b568cf3a8abd273769d213394bb
                type: string
            type: object

- **image\_alias\_untrusted**

    Gets a specific public image alias.
    This untrusted endpoint only works for aliases pointing to public images.

    - `name`: string, required
    - `project`: string, optional

- **image\_export**

    Download the raw image file(s) from the server.
    If the image is in split format, a multipart http transfer occurs.

    - `fingerprint`: string, required
    - `project`: string, optional

- **image\_export\_untrusted**

    Download the raw image file(s) of a public image from the server.
    If the image is in split format, a multipart http transfer occurs.

    - `fingerprint`: string, required
    - `project`: string, optional
    - `secret`: string, optional

- **image\_untrusted**

    Gets a specific public image.

    - `fingerprint`: string, required
    - `project`: string, optional
    - `secret`: string, optional

- **images**

    Returns a list of images (URLs).

    - `filter`: string, optional
    - `project`: string, optional

- **images\_aliases**

    Returns a list of image aliases (URLs).

    - `project`: string, optional

- **images\_aliases\_recursion1**

    Returns a list of image aliases (structs).

    - `project`: string, optional

- **images\_recursion1**

    Returns a list of images (structs).

    - `filter`: string, optional
    - `project`: string, optional

- **images\_recursion1\_untrusted**

    Returns a list of publicly available images (structs).

    - `filter`: string, optional
    - `project`: string, optional

- **images\_untrusted**

    Returns a list of publicly available images (URLs).

    - `filter`: string, optional
    - `project`: string, optional

- **initiate\_image\_upload**

    This generates a background operation including a secret one time key
    in its metadata which can be used to fetch this image from an untrusted
    client.

    - `fingerprint`: string, required
    - `project`: string, optional

- **modify\_image**

    Updates a subset of the image definition.

    - `fingerprint`: string, required
    - `project`: string, optional
    - `body`: image, required

            description: ImagePut represents the modifiable fields of a LXD image
            properties:
              auto_update:
                description: Whether the image should auto-update when a new build is available
                example: true
                type: boolean
              expires_at:
                description: When the image becomes obsolete
                example: 2025-03-23T20:00:00-04:00
                format: date-time
                type: string
              profiles:
                description: List of profiles to use when creating from this image (if none provided by user)
                example:
                  - default
                items:
                  type: string
                type: array
              properties:
                additionalProperties:
                  type: string
                description: Descriptive properties
                example:
                  os: Ubuntu
                  release: focal
                  variant: cloud
                type: object
              public:
                description: Whether the image is available to unauthenticated users
                example: false
                type: boolean
            type: object

- **modify\_images\_alias**

    Updates a subset of the image alias configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: image alias, required

            description: ImageAliasesEntryPut represents the modifiable fields of a LXD image alias
            properties:
              description:
                description: Alias description
                example: Our preferred Ubuntu image
                type: string
              target:
                description: Target fingerprint for the alias
                example: 06b86454720d36b20f94e31c6812e05ec51c1b568cf3a8abd273769d213394bb
                type: string
            type: object

- **push\_image\_untrusted**

    Pushes the data to the target image server.
    This is meant for LXD to LXD communication where a new image entry is
    prepared on the target server and the source server is provided that URL
    and a secret token to push the image content over.

    - `project`: string, optional
    - `body`: image, required

            description: ImagesPost represents the fields available for a new LXD image
            properties:
              aliases:
                description: Aliases to add to the image
                example:
                  - name: foo
                  - name: bar
                items:
                  $ref: '#/definitions/ImageAlias'
                type: array
              auto_update:
                description: Whether the image should auto-update when a new build is available
                example: true
                type: boolean
              compression_algorithm:
                description: Compression algorithm to use when turning an instance into an image
                example: gzip
                type: string
              expires_at:
                description: When the image becomes obsolete
                example: 2025-03-23T20:00:00-04:00
                format: date-time
                type: string
              filename:
                description: Original filename of the image
                example: lxd.tar.xz
                type: string
              profiles:
                description: List of profiles to use when creating from this image (if none provided by user)
                example:
                  - default
                items:
                  type: string
                type: array
              properties:
                additionalProperties:
                  type: string
                description: Descriptive properties
                example:
                  os: Ubuntu
                  release: focal
                  variant: cloud
                type: object
              public:
                description: Whether the image is available to unauthenticated users
                example: false
                type: boolean
              source:
                $ref: '#/definitions/ImagesPostSource'
            type: object

- **push\_images\_export**

    Gets LXD to connect to a remote server and push the image to it.

    - `fingerprint`: string, required
    - `project`: string, optional
    - `body`: image, required

            description: ImageExportPost represents the fields required to export a LXD image
            properties:
              aliases:
                description: List of aliases to set on the image
                items:
                  $ref: '#/definitions/ImageAlias'
                type: array
              certificate:
                description: Remote server certificate
                example: X509 PEM certificate
                type: string
              secret:
                description: Image receive secret
                example: RANDOM-STRING
                type: string
              target:
                description: Target server URL
                example: https://1.2.3.4:8443
                type: string
            type: object

- **rename\_images\_alias**

    Renames an existing image alias.

    - `name`: string, required
    - `project`: string, optional
    - `body`: image alias, required

            description: ImageAliasesEntryPost represents the required fields to rename a LXD image alias
            properties:
              name:
                description: Alias name
                example: ubuntu-20.04
                type: string
            type: object

- **update\_images\_refresh**

    This causes LXD to check the image source server for an updated
    version of the image and if available to refresh the local copy with the
    new version.

    - `fingerprint`: string, required
    - `project`: string, optional

## Instances

- **connect\_instance\_console**

    Connects to the console of an instance.

    The returned operation metadata will contain two websockets, one for data and one for control.

    - `name`: string, required
    - `project`: string, optional
    - `body`: console, optional

            properties:
              height:
                description: Console height in rows (console type only)
                example: 24
                format: int64
                type: integer
              type:
                description: Type of console to attach to (console or vga)
                example: console
                type: string
              width:
                description: Console width in columns (console type only)
                example: 80
                format: int64
                type: integer
            title: InstanceConsolePost represents a LXD instance console request.
            type: object

- **create\_instance**

    Creates a new instance on LXD.
    Depending on the source, this can create an instance from an existing
    local image, remote image, existing local instance or snapshot, remote
    migration stream or backup file.

    - `project`: string, optional
    - `target`: string, optional
    - `body`: instance, optional

            properties:
              architecture:
                description: Architecture name
                example: x86_64
                type: string
              config:
                additionalProperties:
                  type: string
                description: Instance configuration (see doc/instances.md)
                example:
                  security.nesting: true
                type: object
              description:
                description: Instance description
                example: My test instance
                type: string
              devices:
                additionalProperties:
                  additionalProperties:
                    type: string
                  type: object
                description: Instance devices (see doc/instances.md)
                example:
                  root:
                    path: /
                    pool: default
                    type: disk
                type: object
              ephemeral:
                description: Whether the instance is ephemeral (deleted on shutdown)
                example: false
                type: boolean
              instance_type:
                description: 'Cloud instance type (AWS, GCP, Azure, ...) to emulate with limits'
                example: t1.micro
                type: string
              name:
                description: Instance name
                example: foo
                type: string
              profiles:
                description: List of profiles applied to the instance
                example:
                  - default
                items:
                  type: string
                type: array
              restore:
                description: 'If set, instance will be restored to the provided snapshot name'
                example: snap0
                type: string
              source:
                $ref: '#/definitions/InstanceSource'
              stateful:
                description: Whether the instance currently has saved state on disk
                example: false
                type: boolean
              type:
                $ref: '#/definitions/InstanceType'
            title: InstancesPost represents the fields available for a new LXD instance.
            type: object

    - `body`: raw\_backup, optionalsee Spec

- **create\_instance\_backup**

    Creates a new backup.

    - `name`: string, required
    - `project`: string, optional
    - `body`: backup, optional

            properties:
              compression_algorithm:
                description: What compression algorithm to use
                example: gzip
                type: string
              container_only:
                description: 'Whether to ignore snapshots (deprecated, use instance_only)'
                example: false
                type: boolean
              expires_at:
                description: When the backup expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
              instance_only:
                description: Whether to ignore snapshots
                example: false
                type: boolean
              name:
                description: Backup name
                example: backup0
                type: string
              optimized_storage:
                description: Whether to use a pool-optimized binary format (instead of plain tarball)
                example: true
                type: boolean
            title: InstanceBackupsPost represents the fields available for a new LXD instance backup.
            type: object

- **create\_instance\_file**

    Creates a new file in the instance.

    - `name`: string, required
    - `path`: string, optional
    - `project`: string, optional
    - `body`: raw\_file, optionalsee Spec

- **create\_instance\_metadata\_template**

    Creates a new image template file for the instance.

    - `name`: string, required
    - `path`: string, optional
    - `project`: string, optional
    - `body`: raw\_file, optionalsee Spec

- **create\_instance\_snapshot**

    Creates a new snapshot.

    - `name`: string, required
    - `project`: string, optional
    - `body`: snapshot, optional

            properties:
              expires_at:
                description: When the snapshot expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
              name:
                description: Snapshot name
                example: snap0
                type: string
              stateful:
                description: Whether the snapshot should include runtime state
                example: false
                type: boolean
            title: InstanceSnapshotsPost represents the fields available for a new LXD instance snapshot.
            type: object

- **delete\_instance**

    Deletes a specific instance.

    This also deletes anything owned by the instance such as snapshots and backups.

    - `name`: string, required
    - `project`: string, optional

- **delete\_instance\_backup**

    Deletes the instance backup.

    - `backup`: string, required
    - `name`: string, required
    - `project`: string, optional

- **delete\_instance\_console**

    Clears the console log buffer.

    - `name`: string, required
    - `project`: string, optional

- **delete\_instance\_files**

    Removes the file.

    - `name`: string, required
    - `path`: string, optional
    - `project`: string, optional

- **delete\_instance\_log**

    Removes the log file.

    - `filename`: string, required
    - `name`: string, required
    - `project`: string, optional

- **delete\_instance\_metadata\_templates**

    Removes the template file.

    - `name`: string, required
    - `path`: string, optional
    - `project`: string, optional

- **delete\_instance\_snapshot**

    Deletes the instance snapshot.

    - `name`: string, required
    - `snapshot`: string, required
    - `project`: string, optional

- **execute\_in\_instance**

    Executes a command inside an instance.

    The returned operation metadata will contain either 2 or 4 websockets.
    In non-interactive mode, you'll get one websocket for each of stdin, stdout and stderr.
    In interactive mode, a single bi-directional websocket is used for stdin and stdout/stderr.

    An additional "control" socket is always added on top which can be used for out of band communication with LXD.
    This allows sending signals and window sizing information through.

    - `name`: string, required
    - `project`: string, optional
    - `body`: exec, optional

            properties:
              command:
                description: Command and its arguments
                example:
                  - bash
                items:
                  type: string
                type: array
              cwd:
                description: Current working directory for the command
                example: /home/foo/
                type: string
              environment:
                additionalProperties:
                  type: string
                description: Additional environment to pass to the command
                example:
                  FOO: BAR
                type: object
              group:
                description: GID of the user to spawn the command as
                example: 1000
                format: uint32
                type: integer
              height:
                description: Terminal height in rows (for interactive)
                example: 24
                format: int64
                type: integer
              interactive:
                description: Whether the command is to be spawned in interactive mode (singled PTY instead of 3 PIPEs)
                example: true
                type: boolean
              record-output:
                description: Whether to capture the output for later download (requires non-interactive)
                type: boolean
              user:
                description: UID of the user to spawn the command as
                example: 1000
                format: uint32
                type: integer
              wait-for-websocket:
                description: Whether to wait for all websockets to be connected before spawning the command
                example: true
                type: boolean
              width:
                description: Terminal width in characters (for interactive)
                example: 80
                format: int64
                type: integer
            title: InstanceExecPost represents a LXD instance exec request.
            type: object

- **instance**

    Gets a specific instance (basic struct).

    Updates the instance configuration or trigger a snapshot restore.

    - `name`: string, required
    - `project`: string, optional
    - `body`: instance, optional

            properties:
              architecture:
                description: Architecture name
                example: x86_64
                type: string
              config:
                additionalProperties:
                  type: string
                description: Instance configuration (see doc/instances.md)
                example:
                  security.nesting: true
                type: object
              description:
                description: Instance description
                example: My test instance
                type: string
              devices:
                additionalProperties:
                  additionalProperties:
                    type: string
                  type: object
                description: Instance devices (see doc/instances.md)
                example:
                  root:
                    path: /
                    pool: default
                    type: disk
                type: object
              ephemeral:
                description: Whether the instance is ephemeral (deleted on shutdown)
                example: false
                type: boolean
              profiles:
                description: List of profiles applied to the instance
                example:
                  - default
                items:
                  type: string
                type: array
              restore:
                description: 'If set, instance will be restored to the provided snapshot name'
                example: snap0
                type: string
              stateful:
                description: Whether the instance currently has saved state on disk
                example: false
                type: boolean
            title: InstancePut represents the modifiable fields of a LXD instance.
            type: object

- **instance\_backup**

    Gets a specific instance backup.

    - `backup`: string, required
    - `name`: string, required
    - `project`: string, optional

- **instance\_backup\_export**

    Download the raw backup file(s) from the server.

    - `backup`: string, required
    - `name`: string, required
    - `project`: string, optional

- **instance\_backups**

    Returns a list of instance backups (URLs).

    - `name`: string, required
    - `project`: string, optional

- **instance\_backups\_recursion1**

    Returns a list of instance backups (structs).

    - `name`: string, required
    - `project`: string, optional

- **instance\_console**

    Gets the console log for the instance.

    - `name`: string, required
    - `project`: string, optional

- **instance\_files**

    Gets the file content. If it's a directory, a json list of files will be returned instead.

    - `name`: string, required
    - `path`: string, optional
    - `project`: string, optional

- **instance\_log**

    Gets the log file.

    - `filename`: string, required
    - `name`: string, required
    - `project`: string, optional

- **instance\_logs**

    Returns a list of log files (URLs).

    - `name`: string, required
    - `project`: string, optional

- **instance\_metadata**

    Gets the image metadata for the instance.

    Updates the instance image metadata.

    - `name`: string, required
    - `project`: string, optional
    - `body`: metadata, required

            description: ImageMetadata represents LXD image metadata (used in image tarball)
            properties:
              architecture:
                description: Architecture name
                example: x86_64
                type: string
              creation_date:
                description: Image creation data (as UNIX epoch)
                example: 1620655439
                format: int64
                type: integer
              expiry_date:
                description: Image expiry data (as UNIX epoch)
                example: 1620685757
                format: int64
                type: integer
              properties:
                additionalProperties:
                  type: string
                description: Descriptive properties
                example:
                  os: Ubuntu
                  release: focal
                  variant: cloud
                type: object
              templates:
                additionalProperties:
                  $ref: '#/definitions/ImageMetadataTemplate'
                description: Template for files in the image
                type: object
            type: object

- **instance\_metadata\_templates**

    If no path specified, returns a list of template file names.
    If a path is specified, returns the file content.

    - `name`: string, required
    - `path`: string, optional
    - `project`: string, optional

- **instance\_recursion1**

    Gets a specific instance (full struct).

    recursion=1 also includes information about state, snapshots and backups.

    - `name`: string, required
    - `project`: string, optional

- **instance\_snapshot**

    Gets a specific instance snapshot.

    Updates the snapshot config.

    - `name`: string, required
    - `snapshot`: string, required
    - `project`: string, optional
    - `body`: snapshot, optional

            properties:
              expires_at:
                description: When the snapshot expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
            title: InstanceSnapshotPut represents the modifiable fields of a LXD instance snapshot.
            type: object

- **instance\_snapshots**

    Returns a list of instance snapshots (URLs).

    - `name`: string, required
    - `project`: string, optional

- **instance\_snapshots\_recursion1**

    Returns a list of instance snapshots (structs).

    - `name`: string, required
    - `project`: string, optional

- **instance\_state**

    Gets the runtime state of the instance.

    This is a reasonably expensive call as it causes code to be run
    inside of the instance to retrieve the resource usage and network
    information.

    Changes the running state of the instance.

    - `name`: string, required
    - `project`: string, optional
    - `body`: state, optional

            properties:
              action:
                description: 'State change action (start, stop, restart, freeze, unfreeze)'
                example: start
                type: string
              force:
                description: Whether to force the action (for stop and restart)
                example: false
                type: boolean
              stateful:
                description: Whether to store the runtime state (for stop)
                example: false
                type: boolean
              timeout:
                description: How long to wait (in s) before giving up (when force isn't set)
                example: 30
                format: int64
                type: integer
            title: InstanceStatePut represents the modifiable fields of a LXD instance's state.
            type: object

- **instances**

    Returns a list of instances (URLs).

    Changes the running state of all instances.

    - `all-projects`: boolean, optional
    - `filter`: string, optional
    - `project`: string, optional
    - `body`: state, optional

            properties:
              state:
                $ref: '#/definitions/InstanceStatePut'
            title: InstancesPut represents the fields available for a mass update.
            type: object

- **instances\_recursion1**

    Returns a list of instances (basic structs).

    - `all-projects`: boolean, optional
    - `filter`: string, optional
    - `project`: string, optional

- **instances\_recursion2**

    Returns a list of instances (full structs).

    The main difference between recursion=1 and recursion=2 is that the
    latter also includes state and snapshot information allowing for a
    single API call to return everything needed by most clients.

    - `all-projects`: boolean, optional
    - `filter`: string, optional
    - `project`: string, optional

- **migrate\_instance**

    Renames, moves an instance between pools or migrates an instance to another server.

    The returned operation metadata will vary based on what's requested.
    For rename or move within the same server, this is a simple background operation with progress data.
    For migration, in the push case, this will similarly be a background
    operation with progress data, for the pull case, it will be a websocket
    operation with a number of secrets to be passed to the target server.

    - `name`: string, required
    - `project`: string, optional
    - `body`: migration, optional

            properties:
              container_only:
                description: 'Whether snapshots should be discarded (migration only, deprecated, use instance_only)'
                example: false
                type: boolean
              instance_only:
                description: Whether snapshots should be discarded (migration only)
                example: false
                type: boolean
              live:
                description: Whether to perform a live migration (migration only)
                example: false
                type: boolean
              migration:
                description: Whether the instance is being migrated to another server
                example: false
                type: boolean
              name:
                description: New name for the instance
                example: bar
                type: string
              pool:
                description: Target pool for local cross-pool move
                example: baz
                type: string
              project:
                description: Target project for local cross-project move
                example: foo
                type: string
              target:
                $ref: '#/definitions/InstancePostTarget'
            title: InstancePost represents the fields required to rename/move a LXD instance.
            type: object

- **migrate\_instance\_snapshot**

    Renames or migrates an instance snapshot to another server.

    The returned operation metadata will vary based on what's requested.
    For rename or move within the same server, this is a simple background operation with progress data.
    For migration, in the push case, this will similarly be a background
    operation with progress data, for the pull case, it will be a websocket
    operation with a number of secrets to be passed to the target server.

    - `name`: string, required
    - `snapshot`: string, required
    - `project`: string, optional
    - `body`: snapshot, optional

            properties:
              live:
                description: Whether to perform a live migration (requires migration)
                example: false
                type: boolean
              migration:
                description: Whether this is a migration request
                example: false
                type: boolean
              name:
                description: New name for the snapshot
                example: foo
                type: string
              target:
                $ref: '#/definitions/InstancePostTarget'
            title: InstanceSnapshotPost represents the fields required to rename/move a LXD instance snapshot.
            type: object

- **modify\_instance**

    Updates a subset of the instance configuration

    - `name`: string, required
    - `project`: string, optional
    - `body`: instance, optional

            properties:
              architecture:
                description: Architecture name
                example: x86_64
                type: string
              config:
                additionalProperties:
                  type: string
                description: Instance configuration (see doc/instances.md)
                example:
                  security.nesting: true
                type: object
              description:
                description: Instance description
                example: My test instance
                type: string
              devices:
                additionalProperties:
                  additionalProperties:
                    type: string
                  type: object
                description: Instance devices (see doc/instances.md)
                example:
                  root:
                    path: /
                    pool: default
                    type: disk
                type: object
              ephemeral:
                description: Whether the instance is ephemeral (deleted on shutdown)
                example: false
                type: boolean
              profiles:
                description: List of profiles applied to the instance
                example:
                  - default
                items:
                  type: string
                type: array
              restore:
                description: 'If set, instance will be restored to the provided snapshot name'
                example: snap0
                type: string
              stateful:
                description: Whether the instance currently has saved state on disk
                example: false
                type: boolean
            title: InstancePut represents the modifiable fields of a LXD instance.
            type: object

- **modify\_instance\_metadata**

    Updates a subset of the instance image metadata.

    - `name`: string, required
    - `project`: string, optional
    - `body`: metadata, required

            description: ImageMetadata represents LXD image metadata (used in image tarball)
            properties:
              architecture:
                description: Architecture name
                example: x86_64
                type: string
              creation_date:
                description: Image creation data (as UNIX epoch)
                example: 1620655439
                format: int64
                type: integer
              expiry_date:
                description: Image expiry data (as UNIX epoch)
                example: 1620685757
                format: int64
                type: integer
              properties:
                additionalProperties:
                  type: string
                description: Descriptive properties
                example:
                  os: Ubuntu
                  release: focal
                  variant: cloud
                type: object
              templates:
                additionalProperties:
                  $ref: '#/definitions/ImageMetadataTemplate'
                description: Template for files in the image
                type: object
            type: object

- **modify\_instance\_snapshot**

    Updates a subset of the snapshot config.

    - `name`: string, required
    - `snapshot`: string, required
    - `project`: string, optional
    - `body`: snapshot, optional

            properties:
              expires_at:
                description: When the snapshot expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
            title: InstanceSnapshotPut represents the modifiable fields of a LXD instance snapshot.
            type: object

- **rename\_instance\_backup**

    Renames an instance backup.

    - `backup`: string, required
    - `name`: string, required
    - `project`: string, optional
    - `body`: backup, optional

            properties:
              name:
                description: New backup name
                example: backup1
                type: string
            title: InstanceBackupPost represents the fields available for the renaming of a instance backup.
            type: object

## Metrics

- **metrics**

    Gets metrics of instances.

    - `project`: string, optional

## Network ACLs

- **create\_network\_acl**

    Creates a new network ACL.

    - `project`: string, optional
    - `body`: acl, required

            properties:
              config:
                additionalProperties:
                  type: string
                description: ACL configuration map (refer to doc/network-acls.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the ACL
                example: Web servers
                type: string
              egress:
                description: List of egress rules (order independent)
                items:
                  $ref: '#/definitions/NetworkACLRule'
                type: array
              ingress:
                description: List of ingress rules (order independent)
                items:
                  $ref: '#/definitions/NetworkACLRule'
                type: array
              name:
                description: The new name for the ACL
                example: bar
                type: string
            title: NetworkACLsPost used for creating an ACL.
            type: object

- **delete\_network\_acl**

    Removes the network ACL.

    - `name`: string, required
    - `project`: string, optional

- **modify\_network\_acl**

    Updates a subset of the network ACL configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: acl, required

            properties:
              config:
                additionalProperties:
                  type: string
                description: ACL configuration map (refer to doc/network-acls.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the ACL
                example: Web servers
                type: string
              egress:
                description: List of egress rules (order independent)
                items:
                  $ref: '#/definitions/NetworkACLRule'
                type: array
              ingress:
                description: List of ingress rules (order independent)
                items:
                  $ref: '#/definitions/NetworkACLRule'
                type: array
            title: NetworkACLPut used for updating an ACL.
            type: object

- **network\_acl**

    Gets a specific network ACL.

    Updates the entire network ACL configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: acl, required

            properties:
              config:
                additionalProperties:
                  type: string
                description: ACL configuration map (refer to doc/network-acls.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the ACL
                example: Web servers
                type: string
              egress:
                description: List of egress rules (order independent)
                items:
                  $ref: '#/definitions/NetworkACLRule'
                type: array
              ingress:
                description: List of ingress rules (order independent)
                items:
                  $ref: '#/definitions/NetworkACLRule'
                type: array
            title: NetworkACLPut used for updating an ACL.
            type: object

- **network\_acl\_log**

    Gets a specific network ACL log entries.

    - `name`: string, required
    - `project`: string, optional

- **network\_acls**

    Returns a list of network ACLs (URLs).

    - `project`: string, optional

- **network\_acls\_recursion1**

    Returns a list of network ACLs (structs).

    - `project`: string, optional

- **rename\_network\_acl**

    Renames an existing network ACL.

    - `name`: string, required
    - `project`: string, optional
    - `body`: acl, required

            properties:
              name:
                description: The new name for the ACL
                example: bar
                type: string
            title: NetworkACLPost used for renaming an ACL.
            type: object

## Network Forwards

- **create\_network\_forward**

    Creates a new network address forward.

    - `networkName`: string, required
    - `project`: string, optional
    - `body`: forward, required

            description: NetworkForwardsPost represents the fields of a new LXD network address forward
            properties:
              config:
                additionalProperties:
                  type: string
                description: Forward configuration map (refer to doc/network-forwards.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the forward listen IP
                example: My public IP forward
                type: string
              listen_address:
                description: The listen address of the forward
                example: 192.0.2.1
                type: string
              ports:
                description: Port forwards (optional)
                items:
                  $ref: '#/definitions/NetworkForwardPort'
                type: array
            type: object

- **delete\_network\_forward**

    Removes the network address forward.

    - `listenAddress`: string, required
    - `networkName`: string, required
    - `project`: string, optional

- **modify\_network\_forward**

    Updates a subset of the network address forward configuration.

    - `listenAddress`: string, required
    - `networkName`: string, required
    - `project`: string, optional
    - `body`: forward, required

            description: NetworkForwardPut represents the modifiable fields of a LXD network address forward
            properties:
              config:
                additionalProperties:
                  type: string
                description: Forward configuration map (refer to doc/network-forwards.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the forward listen IP
                example: My public IP forward
                type: string
              ports:
                description: Port forwards (optional)
                items:
                  $ref: '#/definitions/NetworkForwardPort'
                type: array
            type: object

- **network\_forward**

    Gets a specific network address forward.

    Updates the entire network address forward configuration.

    - `listenAddress`: string, required
    - `networkName`: string, required
    - `project`: string, optional
    - `body`: forward, required

            description: NetworkForwardPut represents the modifiable fields of a LXD network address forward
            properties:
              config:
                additionalProperties:
                  type: string
                description: Forward configuration map (refer to doc/network-forwards.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the forward listen IP
                example: My public IP forward
                type: string
              ports:
                description: Port forwards (optional)
                items:
                  $ref: '#/definitions/NetworkForwardPort'
                type: array
            type: object

- **network\_forward\_recursion1**

    Returns a list of network address forwards (structs).

    - `networkName`: string, required
    - `project`: string, optional

- **network\_forwards**

    Returns a list of network address forwards (URLs).

    - `networkName`: string, required
    - `project`: string, optional

## Network Peers

- **create\_network\_peer**

    Initiates/creates a new network peering.

    - `networkName`: string, required
    - `project`: string, optional
    - `body`: peer, required

            description: NetworkPeersPost represents the fields of a new LXD network peering
            properties:
              config:
                additionalProperties:
                  type: string
                description: Peer configuration map (refer to doc/network-peers.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the peer
                example: Peering with network1 in project1
                type: string
              name:
                description: Name of the peer
                example: project1-network1
                type: string
              target_network:
                description: Name of the target network
                example: network1
                type: string
              target_project:
                description: Name of the target project
                example: project1
                type: string
            type: object

- **delete\_network\_peer**

    Removes the network peering.

    - `networkName`: string, required
    - `peerName`: string, required
    - `project`: string, optional

- **modify\_network\_peer**

    Updates a subset of the network peering configuration.

    - `networkName`: string, required
    - `peerName`: string, required
    - `project`: string, optional
    - `body`: Peer, required

            description: NetworkPeerPut represents the modifiable fields of a LXD network peering
            properties:
              config:
                additionalProperties:
                  type: string
                description: Peer configuration map (refer to doc/network-peers.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the peer
                example: Peering with network1 in project1
                type: string
            type: object

- **network\_peer**

    Gets a specific network peering.

    Updates the entire network peering configuration.

    - `networkName`: string, required
    - `peerName`: string, required
    - `project`: string, optional
    - `body`: peer, required

            description: NetworkPeerPut represents the modifiable fields of a LXD network peering
            properties:
              config:
                additionalProperties:
                  type: string
                description: Peer configuration map (refer to doc/network-peers.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the peer
                example: Peering with network1 in project1
                type: string
            type: object

- **network\_peer\_recursion1**

    Returns a list of network peers (structs).

    - `networkName`: string, required
    - `project`: string, optional

- **network\_peers**

    Returns a list of network peers (URLs).

    - `networkName`: string, required
    - `project`: string, optional

## Network Zones

- **create\_network\_zone**

    Creates a new network zone.

    - `project`: string, optional
    - `body`: zone, required

            description: NetworkZonesPost represents the fields of a new LXD network zone
            properties:
              config:
                additionalProperties:
                  type: string
                description: Zone configuration map (refer to doc/network-zones.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the network zone
                example: Internal domain
                type: string
              name:
                description: The name of the zone (DNS domain name)
                example: example.net
                type: string
            type: object

- **create\_network\_zone\_record**

    Creates a new network zone record.

    - `zone`: string, required
    - `project`: string, optional
    - `body`: zone, required

            description: NetworkZoneRecordsPost represents the fields of a new LXD network zone record
            properties:
              config:
                additionalProperties:
                  type: string
                description: Advanced configuration for the record
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the record
                example: SPF record
                type: string
              entries:
                description: Entries in the record
                items:
                  $ref: '#/definitions/NetworkZoneRecordEntry'
                type: array
              name:
                description: The record name in the zone
                example: '@'
                type: string
            type: object

- **delete\_network\_zone**

    Removes the network zone.

    - `name`: string, required
    - `project`: string, optional

- **delete\_network\_zone\_record**

    Removes the network zone record.

    - `name`: string, required
    - `zone`: string, required
    - `project`: string, optional

- **modify\_network\_zone**

    Updates a subset of the network zone configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: zone, required

            description: NetworkZonePut represents the modifiable fields of a LXD network zone
            properties:
              config:
                additionalProperties:
                  type: string
                description: Zone configuration map (refer to doc/network-zones.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the network zone
                example: Internal domain
                type: string
            type: object

- **modify\_network\_zone\_record**

    Updates a subset of the network zone record configuration.

    - `name`: string, required
    - `zone`: string, required
    - `project`: string, optional
    - `body`: zone, required

            description: NetworkZoneRecordPut represents the modifiable fields of a LXD network zone record
            properties:
              config:
                additionalProperties:
                  type: string
                description: Advanced configuration for the record
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the record
                example: SPF record
                type: string
              entries:
                description: Entries in the record
                items:
                  $ref: '#/definitions/NetworkZoneRecordEntry'
                type: array
            type: object

- **network\_zone**

    Gets a specific network zone.

    Updates the entire network zone configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: zone, required

            description: NetworkZonePut represents the modifiable fields of a LXD network zone
            properties:
              config:
                additionalProperties:
                  type: string
                description: Zone configuration map (refer to doc/network-zones.md)
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the network zone
                example: Internal domain
                type: string
            type: object

- **network\_zone\_record**

    Gets a specific network zone record.

    Updates the entire network zone record configuration.

    - `name`: string, required
    - `zone`: string, required
    - `project`: string, optional
    - `body`: zone, required

            description: NetworkZoneRecordPut represents the modifiable fields of a LXD network zone record
            properties:
              config:
                additionalProperties:
                  type: string
                description: Advanced configuration for the record
                example:
                  user.mykey: foo
                type: object
              description:
                description: Description of the record
                example: SPF record
                type: string
              entries:
                description: Entries in the record
                items:
                  $ref: '#/definitions/NetworkZoneRecordEntry'
                type: array
            type: object

- **network\_zone\_records**

    Returns a list of network zone records (URLs).

    - `zone`: string, required
    - `project`: string, optional

- **network\_zone\_records\_recursion1**

    Returns a list of network zone records (structs).

    - `zone`: string, required
    - `project`: string, optional

- **network\_zones**

    Returns a list of network zones (URLs).

    - `project`: string, optional

- **network\_zones\_recursion1**

    Returns a list of network zones (structs).

    - `project`: string, optional

## Networks

- **create\_network**

    Creates a new network.
    When clustered, most network types require individual POST for each cluster member prior to a global POST.

    - `project`: string, optional
    - `target`: string, optional
    - `body`: network, required

            description: NetworksPost represents the fields of a new LXD network
            properties:
              config:
                additionalProperties:
                  type: string
                description: Network configuration map (refer to doc/networks.md)
                example:
                  ipv4.address: 10.0.0.1/24
                  ipv4.nat: true
                  ipv6.address: none
                type: object
              description:
                description: Description of the profile
                example: My new LXD bridge
                type: string
              name:
                description: The name of the new network
                example: lxdbr1
                type: string
              type:
                description: The network type (refer to doc/networks.md)
                example: bridge
                type: string
            type: object

- **delete\_network**

    Removes the network.

    - `name`: string, required
    - `project`: string, optional

- **modify\_network**

    Updates a subset of the network configuration.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: network, required

            description: NetworkPut represents the modifiable fields of a LXD network
            properties:
              config:
                additionalProperties:
                  type: string
                description: Network configuration map (refer to doc/networks.md)
                example:
                  ipv4.address: 10.0.0.1/24
                  ipv4.nat: true
                  ipv6.address: none
                type: object
              description:
                description: Description of the profile
                example: My new LXD bridge
                type: string
            type: object

- **network**

    Gets a specific network.

    Updates the entire network configuration.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: network, required

            description: NetworkPut represents the modifiable fields of a LXD network
            properties:
              config:
                additionalProperties:
                  type: string
                description: Network configuration map (refer to doc/networks.md)
                example:
                  ipv4.address: 10.0.0.1/24
                  ipv4.nat: true
                  ipv6.address: none
                type: object
              description:
                description: Description of the profile
                example: My new LXD bridge
                type: string
            type: object

- **networks**

    Returns a list of networks (URLs).

    - `project`: string, optional

- **networks\_leases**

    Returns a list of DHCP leases for the network.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **networks\_recursion1**

    Returns a list of networks (structs).

    - `project`: string, optional

- **networks\_state**

    Returns the current network state information.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **rename\_network**

    Renames an existing network.

    - `name`: string, required
    - `project`: string, optional
    - `body`: network, required

            description: NetworkPost represents the fields required to rename a LXD network
            properties:
              name:
                description: The new name for the network
                example: lxdbr1
                type: string
            type: object

## Operations

- **delete\_operation**

    Cancels the operation if supported.

    - `id`: string, required

- **operation**

    Gets the operation state.

    - `id`: string, required

- **operation\_wait**

    Waits for the operation to reach a final state (or timeout) and retrieve its final state.

    - `id`: string, required
    - `timeout`: integer, optional

- **operation\_wait\_untrusted**

    Waits for the operation to reach a final state (or timeout) and retrieve its final state.

    When accessed by an untrusted user, the secret token must be provided.

    - `id`: string, required
    - `secret`: string, optional
    - `timeout`: integer, optional

- **operation\_websocket**

    Connects to an associated websocket stream for the operation.
    This should almost never be done directly by a client, instead it's
    meant for LXD to LXD communication with the client only relaying the
    connection information to the servers.

    - `id`: string, required
    - `secret`: string, optional

- **operation\_websocket\_untrusted**

    Connects to an associated websocket stream for the operation.
    This should almost never be done directly by a client, instead it's
    meant for LXD to LXD communication with the client only relaying the
    connection information to the servers.

    The untrusted endpoint is used by the target server to connect to the source server.
    Authentication is performed through the secret token.

    - `id`: string, required
    - `secret`: string, optional

- **operations**

    Returns a dict of operation type to operation list (URLs).

- **operations\_recursion1**

    Returns a list of operations (structs).

    - `project`: string, optional

## Profiles

- **create\_profile**

    Creates a new profile.

    - `project`: string, optional
    - `body`: profile, required

            description: ProfilesPost represents the fields of a new LXD profile
            properties:
              config:
                additionalProperties:
                  type: string
                description: Instance configuration map (refer to doc/instances.md)
                example:
                  limits.cpu: 4
                  limits.memory: 4GiB
                type: object
              description:
                description: Description of the profile
                example: Medium size instances
                type: string
              devices:
                additionalProperties:
                  additionalProperties:
                    type: string
                  type: object
                description: List of devices
                example:
                  eth0:
                    name: eth0
                    network: lxdbr0
                    type: nic
                  root:
                    path: /
                    pool: default
                    type: disk
                type: object
              name:
                description: The name of the new profile
                example: foo
                type: string
            type: object

- **delete\_profile**

    Removes the profile.

    - `name`: string, required
    - `project`: string, optional

- **modify\_profile**

    Updates a subset of the profile configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: profile, required

            description: ProfilePut represents the modifiable fields of a LXD profile
            properties:
              config:
                additionalProperties:
                  type: string
                description: Instance configuration map (refer to doc/instances.md)
                example:
                  limits.cpu: 4
                  limits.memory: 4GiB
                type: object
              description:
                description: Description of the profile
                example: Medium size instances
                type: string
              devices:
                additionalProperties:
                  additionalProperties:
                    type: string
                  type: object
                description: List of devices
                example:
                  eth0:
                    name: eth0
                    network: lxdbr0
                    type: nic
                  root:
                    path: /
                    pool: default
                    type: disk
                type: object
            type: object

- **profile**

    Gets a specific profile.

    Updates the entire profile configuration.

    - `name`: string, required
    - `project`: string, optional
    - `body`: profile, required

            description: ProfilePut represents the modifiable fields of a LXD profile
            properties:
              config:
                additionalProperties:
                  type: string
                description: Instance configuration map (refer to doc/instances.md)
                example:
                  limits.cpu: 4
                  limits.memory: 4GiB
                type: object
              description:
                description: Description of the profile
                example: Medium size instances
                type: string
              devices:
                additionalProperties:
                  additionalProperties:
                    type: string
                  type: object
                description: List of devices
                example:
                  eth0:
                    name: eth0
                    network: lxdbr0
                    type: nic
                  root:
                    path: /
                    pool: default
                    type: disk
                type: object
            type: object

- **profiles**

    Returns a list of profiles (URLs).

    - `project`: string, optional

- **profiles\_recursion1**

    Returns a list of profiles (structs).

    - `project`: string, optional

- **rename\_profile**

    Renames an existing profile.

    - `name`: string, required
    - `project`: string, optional
    - `body`: profile, required

            description: ProfilePost represents the fields required to rename a LXD profile
            properties:
              name:
                description: The new name for the profile
                example: bar
                type: string
            type: object

## Projects

- **create\_project**

    Creates a new project.

    - `body`: project, required

            description: ProjectsPost represents the fields of a new LXD project
            properties:
              config:
                additionalProperties:
                  type: string
                description: Project configuration map (refer to doc/projects.md)
                example:
                  features.networks: false
                  features.profiles: true
                type: object
              description:
                description: Description of the project
                example: My new project
                type: string
              name:
                description: The name of the new project
                example: foo
                type: string
            type: object

- **delete\_project**

    Removes the project.

    - `name`: string, required

- **modify\_project**

    Updates a subset of the project configuration.

    - `name`: string, required
    - `body`: project, required

            description: ProjectPut represents the modifiable fields of a LXD project
            properties:
              config:
                additionalProperties:
                  type: string
                description: Project configuration map (refer to doc/projects.md)
                example:
                  features.networks: false
                  features.profiles: true
                type: object
              description:
                description: Description of the project
                example: My new project
                type: string
            type: object

- **project**

    Gets a specific project.

    Updates the entire project configuration.

    - `name`: string, required
    - `body`: project, required

            description: ProjectPut represents the modifiable fields of a LXD project
            properties:
              config:
                additionalProperties:
                  type: string
                description: Project configuration map (refer to doc/projects.md)
                example:
                  features.networks: false
                  features.profiles: true
                type: object
              description:
                description: Description of the project
                example: My new project
                type: string
            type: object

- **project\_state**

    Gets a specific project resource consumption information.

    - `name`: string, required

- **projects**

    Returns a list of projects (URLs).

- **projects\_recursion1**

    Returns a list of projects (structs).

- **rename\_project**

    Renames an existing project.

    - `name`: string, required
    - `body`: project, required

            description: ProjectPost represents the fields required to rename a LXD project
            properties:
              name:
                description: The new name for the project
                example: bar
                type: string
            type: object

## Server

- **api**

    Returns a list of supported API versions (URLs).

    Internal API endpoints are not reported as those aren't versioned and
    should only be used by LXD itself.

- **events**

    Connects to the event API using websocket.

    - `project`: string, optional
    - `type`: string, optional

- **modify\_server**

    Updates a subset of the server configuration.

    - `target`: string, optional
    - `body`: server, required

            description: ServerPut represents the modifiable fields of a LXD server configuration
            properties:
              config:
                additionalProperties:
                  type: object
                description: Server configuration map (refer to doc/server.md)
                example:
                  core.https_address: :8443
                  core.trust_password: true
                type: object
            type: object

- **resources**

    Gets the hardware information profile of the LXD server.

    - `target`: string, optional

- **server**

    Shows the full server environment and configuration.

    Updates the entire server configuration.

    - `project`: string, optional
    - `target`: string, optional
    - `body`: server, required

            description: ServerPut represents the modifiable fields of a LXD server configuration
            properties:
              config:
                additionalProperties:
                  type: object
                description: Server configuration map (refer to doc/server.md)
                example:
                  core.https_address: :8443
                  core.trust_password: true
                type: object
            type: object

- **server\_untrusted**

    Shows a small subset of the server environment and configuration
    which is required by untrusted clients to reach a server.

    The \`?public\` part of the URL isn't required, it's simply used to
    separate the two behaviors of this endpoint.

## Storage

- **create\_storage\_pool**

    Creates a new storage pool.
    When clustered, storage pools require individual POST for each cluster member prior to a global POST.

    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage, required

            description: StoragePoolsPost represents the fields of a new LXD storage pool
            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage pool configuration map (refer to doc/storage.md)
                example:
                  volume.block.filesystem: ext4
                  volume.size: 50GiB
                type: object
              description:
                description: Description of the storage pool
                example: Local SSD pool
                type: string
              driver:
                description: 'Storage pool driver (btrfs, ceph, cephfs, dir, lvm or zfs)'
                example: zfs
                type: string
              name:
                description: Storage pool name
                example: local
                type: string
            type: object

- **create\_storage\_pool\_volume**

    Creates a new storage volume.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: volume, required

            description: StorageVolumesPost represents the fields of a new LXD storage pool volume
            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage volume configuration map (refer to doc/storage.md)
                example:
                  size: 50GiB
                  zfs.remove_snapshots: true
                type: object
              content_type:
                description: Volume content type (filesystem or block)
                example: filesystem
                type: string
              description:
                description: Description of the storage volume
                example: My custom volume
                type: string
              name:
                description: Volume name
                example: foo
                type: string
              restore:
                description: Name of a snapshot to restore
                example: snap0
                type: string
              source:
                $ref: '#/definitions/StorageVolumeSource'
              type:
                description: 'Volume type (container, custom, image or virtual-machine)'
                example: custom
                type: string
            type: object

- **create\_storage\_pool\_volumes\_backup**

    Creates a new storage volume backup.

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: volume, required

            description: StoragePoolVolumeBackupsPost represents the fields available for a new LXD volume backup
            properties:
              compression_algorithm:
                description: What compression algorithm to use
                example: gzip
                type: string
              expires_at:
                description: When the backup expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
              name:
                description: Backup name
                example: backup0
                type: string
              optimized_storage:
                description: Whether to use a pool-optimized binary format (instead of plain tarball)
                example: true
                type: boolean
              volume_only:
                description: Whether to ignore snapshots
                example: false
                type: boolean
            type: object

- **create\_storage\_pool\_volumes\_snapshot**

    Creates a new storage volume snapshot.

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: volume, required

            description: StorageVolumeSnapshotsPost represents the fields available for a new LXD storage volume snapshot
            properties:
              expires_at:
                description: When the snapshot expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
              name:
                description: Snapshot name
                example: snap0
                type: string
            type: object

- **create\_storage\_pool\_volumes\_type**

    Creates a new storage volume (type specific endpoint).

    - `name`: string, required
    - `type`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: volume, required

            description: StorageVolumesPost represents the fields of a new LXD storage pool volume
            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage volume configuration map (refer to doc/storage.md)
                example:
                  size: 50GiB
                  zfs.remove_snapshots: true
                type: object
              content_type:
                description: Volume content type (filesystem or block)
                example: filesystem
                type: string
              description:
                description: Description of the storage volume
                example: My custom volume
                type: string
              name:
                description: Volume name
                example: foo
                type: string
              restore:
                description: Name of a snapshot to restore
                example: snap0
                type: string
              source:
                $ref: '#/definitions/StorageVolumeSource'
              type:
                description: 'Volume type (container, custom, image or virtual-machine)'
                example: custom
                type: string
            type: object

- **delete\_storage\_pool\_volume\_type**

    Removes the storage volume.

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **delete\_storage\_pool\_volumes\_type\_backup**

    Deletes a new storage volume backup.

    - `backup`: string, required
    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **delete\_storage\_pool\_volumes\_type\_snapshot**

    Deletes a new storage volume snapshot.

    - `name`: string, required
    - `snapshot`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **delete\_storage\_pools**

    Removes the storage pool.

    - `name`: string, required
    - `project`: string, optional

- **migrate\_storage\_pool\_volume\_type**

    Renames, moves a storage volume between pools or migrates an instance to another server.

    The returned operation metadata will vary based on what's requested.
    For rename or move within the same server, this is a simple background operation with progress data.
    For migration, in the push case, this will similarly be a background
    operation with progress data, for the pull case, it will be a websocket
    operation with a number of secrets to be passed to the target server.

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: migration, optional

            description: StorageVolumePost represents the fields required to rename a LXD storage pool volume
            properties:
              migration:
                description: Initiate volume migration
                example: false
                type: boolean
              name:
                description: New volume name
                example: foo
                type: string
              pool:
                description: New storage pool
                example: remote
                type: string
              project:
                description: New project name
                example: foo
                type: string
              target:
                $ref: '#/definitions/StorageVolumePostTarget'
              volume_only:
                description: Whether snapshots should be discarded (migration only)
                example: false
                type: boolean
            type: object

- **modify\_storage\_pool**

    Updates a subset of the storage pool configuration.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage pool, required

            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage pool configuration map (refer to doc/storage.md)
                example:
                  volume.block.filesystem: ext4
                  volume.size: 50GiB
                type: object
              description:
                description: Description of the storage pool
                example: Local SSD pool
                type: string
            title: StoragePoolPut represents the modifiable fields of a LXD storage pool.
            type: object

- **modify\_storage\_pool\_volume\_type**

    Updates a subset of the storage volume configuration.

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage volume, required

            description: StorageVolumePut represents the modifiable fields of a LXD storage volume
            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage volume configuration map (refer to doc/storage.md)
                example:
                  size: 50GiB
                  zfs.remove_snapshots: true
                type: object
              description:
                description: Description of the storage volume
                example: My custom volume
                type: string
              restore:
                description: Name of a snapshot to restore
                example: snap0
                type: string
            type: object

- **modify\_storage\_pool\_volumes\_type\_snapshot**

    Updates a subset of the storage volume snapshot configuration.

    - `name`: string, required
    - `snapshot`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage volume snapshot, required

            description: StorageVolumeSnapshotPut represents the modifiable fields of a LXD storage volume
            properties:
              description:
                description: Description of the storage volume
                example: My custom volume
                type: string
              expires_at:
                description: When the snapshot expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
            type: object

- **rename\_storage\_pool\_volumes\_type\_backup**

    Renames a storage volume backup.

    - `backup`: string, required
    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: volume rename, required

            description: StorageVolumeSnapshotPost represents the fields required to rename/move a LXD storage volume snapshot
            properties:
              name:
                description: New snapshot name
                example: snap1
                type: string
            type: object

- **rename\_storage\_pool\_volumes\_type\_snapshot**

    Renames a storage volume snapshot.

    - `name`: string, required
    - `snapshot`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: volume rename, required

            description: StorageVolumeSnapshotPost represents the fields required to rename/move a LXD storage volume snapshot
            properties:
              name:
                description: New snapshot name
                example: snap1
                type: string
            type: object

- **storage\_pool**

    Gets a specific storage pool.

    Updates the entire storage pool configuration.

    - `name`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage pool, required

            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage pool configuration map (refer to doc/storage.md)
                example:
                  volume.block.filesystem: ext4
                  volume.size: 50GiB
                type: object
              description:
                description: Description of the storage pool
                example: Local SSD pool
                type: string
            title: StoragePoolPut represents the modifiable fields of a LXD storage pool.
            type: object

- **storage\_pool\_resources**

    Gets the usage information for the storage pool.

    - `name`: string, required
    - `target`: string, optional

- **storage\_pool\_volume\_type**

    Gets a specific storage volume.

    Updates the entire storage volume configuration.

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage volume, required

            description: StorageVolumePut represents the modifiable fields of a LXD storage volume
            properties:
              config:
                additionalProperties:
                  type: string
                description: Storage volume configuration map (refer to doc/storage.md)
                example:
                  size: 50GiB
                  zfs.remove_snapshots: true
                type: object
              description:
                description: Description of the storage volume
                example: My custom volume
                type: string
              restore:
                description: Name of a snapshot to restore
                example: snap0
                type: string
            type: object

- **storage\_pool\_volume\_type\_state**

    Gets a specific storage volume state (usage data).

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes**

    Returns a list of storage volumes (URLs).

    - `name`: string, required
    - `filter`: string, optional
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_recursion1**

    Returns a list of storage volumes (structs).

    - `name`: string, required
    - `filter`: string, optional
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type**

    Returns a list of storage volumes (URLs) (type specific endpoint).

    - `name`: string, required
    - `type`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_backup**

    Gets a specific storage volume backup.

    - `backup`: string, required
    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_backup\_export**

    Download the raw backup file from the server.

    - `backup`: string, required
    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_backups**

    Returns a list of storage volume backups (URLs).

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_backups\_recursion1**

    Returns a list of storage volume backups (structs).

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_recursion1**

    Returns a list of storage volumes (structs) (type specific endpoint).

    - `name`: string, required
    - `type`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_snapshot**

    Gets a specific storage volume snapshot.

    Updates the entire storage volume snapshot configuration.

    - `name`: string, required
    - `snapshot`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional
    - `body`: storage volume snapshot, required

            description: StorageVolumeSnapshotPut represents the modifiable fields of a LXD storage volume
            properties:
              description:
                description: Description of the storage volume
                example: My custom volume
                type: string
              expires_at:
                description: When the snapshot expires (gets auto-deleted)
                example: 2021-03-23T17:38:37.753398689-04:00
                format: date-time
                type: string
            type: object

- **storage\_pool\_volumes\_type\_snapshots**

    Returns a list of storage volume snapshots (URLs).

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pool\_volumes\_type\_snapshots\_recursion1**

    Returns a list of storage volume snapshots (structs).

    - `name`: string, required
    - `type`: string, required
    - `volume`: string, required
    - `project`: string, optional
    - `target`: string, optional

- **storage\_pools**

    Returns a list of storage pools (URLs).

    - `project`: string, optional

- **storage\_pools\_recursion1**

    Returns a list of storage pools (structs).

    - `project`: string, optional

## Warnings

- **delete\_warning**

    Removes the warning.

    - `uuid`: string, required

- **modify\_warning**

    Updates a subset of the warning status.

    - `uuid`: string, required
    - `body`: warning, required

            properties:
              status:
                description: 'Status of the warning (new, acknowledged, or resolved)'
                example: new
                type: string
            title: WarningPut represents the modifiable fields of a warning.
            type: object

- **warning**

    Gets a specific warning.

    Updates the warning status.

    - `uuid`: string, required
    - `body`: warning, required

            properties:
              status:
                description: 'Status of the warning (new, acknowledged, or resolved)'
                example: new
                type: string
            title: WarningPut represents the modifiable fields of a warning.
            type: object

- **warnings**

    Returns a list of warnings.

    - `project`: string, optional

- **warnings\_recursion1**

    Returns a list of warnings (structs).

    - `project`: string, optional

# PSEUDO OBJECT ORIENTATION

Just for the sake of experimentation, I added a sub-package `lxd::instance`. To add OO-flavour, you
simply bless the instance HASH with it:

    my $r = $lxd->instance( name => "my-container" )->get;
    my $i = bless $r, 'lxd::instance';

From then on, the following methods can operate on it:

- `restart`
- `start`
- `freeze`
- `unfreeze`
- `stop`
- `state`

Well, I'm not a big fan of objects.

# EXAMPLES

I encourage you to look at the `02_instances.t` test suite. It will show a complete life cycle for
containers.

# SEE ALSO

- [Linux::LXC](https://metacpan.org/pod/Linux::LXC)

    uses actually the existing lxc client to get the information

- [https://github.com/jipipayo/Linux-REST-LXD](https://github.com/jipipayo/Linux-REST-LXD)

    pretty old, never persued

# HINTS

- How to generate an SSL client certificate for LXD

    First, I found one client certificate (plus the key) in my installation at:

        /root/snap/lxd/common/config/

    Alternatively, [you can run your own small CA, generate a .crt and .key for a client, and then
    add it to lxd to trust it](https://serverfault.com/questions/882880/authenticate-to-lxd-rest-api-over-network-certificate-auth-keeps-failing).

    More on this topic is [here](https://linuxcontainers.org/lxd/docs/master/authentication/)

- How to find the SSL fingerprint for an LXD server

    With recent versions of LXD this is fairly easy:

        $ lxc info|grep fingerprint

    It is a SHA265 hash, so you will have to prefix it with `sha256$` (no blanks) when you pass it to `SSL_fingerprint`.

    Alternatively, you can try to find the server certificate and use `openssl` to derive a fingerprint of your choice.

# ISSUES

Open issues are probably best put onto [Github](https://github.com/drrrho/net-async-webservice-lxd)

# AUTHOR

Robert Barta, `<rho at devc.at>`

# CREDITS

[IO::Async](https://metacpan.org/pod/IO::Async), [Net::Async::HTTP](https://metacpan.org/pod/Net::Async::HTTP), [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) and friends are amazing.

# LICENSE AND COPYRIGHT

Copyright 2022 Robert Barta.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
