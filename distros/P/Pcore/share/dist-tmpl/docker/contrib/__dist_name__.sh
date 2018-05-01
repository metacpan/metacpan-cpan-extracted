#!/bin/bash

set -e

SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

TAG=latest
NAME=<: $dockerhub_dist_repo_name :>
DOCKERHUB_NAMESPACE=<: $dockerhub_dist_repo_namespace :>
SERVICE=0

# container restart policy
# https://docs.docker.com/config/containers/start-containers-automatically/
RESTART=always

# seconds to wait for stop before killing container
# https://docs.docker.com/engine/reference/commandline/stop/#options
KILL_TIMEOUT=10

DOCKER_CONTAINER_ARGS="
    -v $SCRIPT_DIR/:/var/local/$NAME/data/ \
    -p 80:80/tcp \
    -p 443:443/tcp \
"

source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/docker.sh || echo false ) "$@"
