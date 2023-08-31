#!/bin/bash
set -Euxo pipefail
IP=()
for i in $(seq 0 5); do
    docker stop "redis-cluster-$i" || :
    docker run -d --rm --name "redis-cluster-$i" redis:7 redis-server --cluster-enabled yes --cluster-config-file nodes.conf
    IP+=("$(docker inspect "redis-cluster-$i" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'):6379")
done

export IFS=' '
echo "${IP[@]}"
docker exec -ti redis-cluster-0 redis-cli --cluster create "${IP[@]}" --cluster-replicas 1 --cluster-yes
