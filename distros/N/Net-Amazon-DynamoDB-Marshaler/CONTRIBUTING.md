# Contributing

## Running test suite w/ Docker

You need to have the following prerequisites installed:

  * Docker
  * Docker Compose

Build the image:

    docker-compose build development

Run the suite:

    docker-compose run development prove -l

## Releasing

    $EDITOR Changes
    docker-compose run development milla test
    docker-compose run development milla release
