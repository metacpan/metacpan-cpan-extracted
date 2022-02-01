package Mock::Podman::Service::Routes;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Controller';

sub Any {
    my $Self = shift;

    return $Self->render(
        template => join( '/', uc $Self->req->method, $Self->stash('route') ),
        variant  => $Self->app->mode,
        format   => 'json',
    );
}

1;

__DATA__
@@ GET/version.json.ep
{
  "Version": "3.0.1"
}
@@ GET/v3.0.1/libpod/info.json.ep
{
  "version":
  {
    "APIVersion": "3.0.0",
    "Version": "3.0.1",
    "GoVersion": "go1.15.9",
    "GitCommit": "",
    "BuiltTime": "Thu Jan  1 01:00:00 1970",
    "Built": 0,
    "OsArch": "linux/amd64"
  }
}
@@ GET/v3.0.1/libpod/system/df.json.ep
{
  "Images": [
      {
      "Repository": "docker.io/library/hello-world",
      "Size": 22491,
      "Containers": 1
    },
    {
      "Repository": "docker.io/library/debian",
      "Size": 129078038,
      "Containers": 1
    }
  ],
    "Containers": [
    {
     "Size": 13256,
     "Names": "hello"
    }
  ],
  "Volumes": [
    {
      "VolumeName": "volume",
      "Size": 0
    }
  ]
}
@@ GET/v3.0.1/libpod/info.json.ep
{
  "host": {},
  "store": {},
  "registries": {},
  "version": {
    "APIVersion": "3.0.0",
    "Version": "3.0.1",
    "GoVersion": "go1.15.9",
    "GitCommit": "",
    "BuiltTime": "Thu Jan  1 01:00:00 1970",
    "Built": 0,
    "OsArch": "linux/amd64"
  }
}
@@ GET/v3.0.1/libpod/images/json.json.ep
[
  {
    "RepoTags": [
      "docker.io/library/hello-world:latest"
    ]
  },
  {
    "RepoTags": [
      "localhost/goodbye:latest"
    ]
  }
]
@@GET/v3.0.1/libpod/containers/json.json.ep
[
  {
    "Names": [
      "webserver"
    ]
  }
]
@@POST/v3.0.1/libpod/images/pull.json.ep
{
  "ok": true
}
@@POST/v3.0.1/libpod/build.json.ep
{
  "ok": true
}
@@GET/v3.0.1/libpod/images/localhost/goodbye/json.json.ep
{
  "Id": "a76ad2934d4d6b478541c7d7df93c64dc0dcfd780472e85f2b3133fa6ea01ab7",
  "RepoTags": [
    "localhost/goodbye:latest"
  ],
  "Created": "2022-01-26T17:25:47.30940821Z",
  "Size": 786563
}
@@DELETE/v3.0.1/libpod/images/localhost/goodbye.json.ep
{
    "ok": true
}
@@POST/v3.0.1/libpod/containers/create.json.ep
{
    "ok": true
}
@@GET/v3.0.1/libpod/containers/hello/json.json.ep
{
  "Id": "12c18c554c9087de0fc7584db27e9f621eb6534001881f7276ffabee5e359234",
  "Created": "2022-01-26T22:49:15.906680921+01:00",
  "State": {
    "Status": "configured"
  },
  "ImageName": "docker.io/library/hello-world",
  "Config": {
   "Cmd": [
      "/hello"
    ]
  }
}
@@DELETE/v3.0.1/libpod/containers/hello.json.ep
{
  "ok": true
}
@@POST/v3.0.1/libpod/containers/hello/start.json.ep
{
  "ok": true
}
@@POST/v3.0.1/libpod/containers/hello/stop.json.ep
{
  "ok": true
}
@@POST/v3.0.1/libpod/containers/hello/kill.json.ep
{
  "ok": true
}
@@exception.development.json.ep
{
  "message": "Not found."
}
