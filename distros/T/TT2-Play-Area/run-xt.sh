#!/bin/sh

docker-compose up -d
# perhaps move this dep conditionally into the Dockerfile?
docker-compose exec -u root test cpanm WebDriver::Tiny
docker-compose exec test prove -l xt t
ret=$?
docker-compose down
exit $ret
