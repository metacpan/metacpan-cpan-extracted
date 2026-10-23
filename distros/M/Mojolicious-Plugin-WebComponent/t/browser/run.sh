#!/bin/sh
# Runs the browser checks: the plugin under `prefork -w 2` in a perl container,
# Chromium (Playwright) in a second container, both in one podman pod.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
perl_image=${WEBCOMPONENT_PERL_IMAGE:-docker.io/library/perl:5.42-slim-threaded}
pw_image=${WEBCOMPONENT_PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.49.0-noble}
pod=wcpod-$$

cleanup() { podman pod rm -f "$pod" >/dev/null 2>&1 || true; }
trap cleanup EXIT

podman pod create --name "$pod" >/dev/null
podman run -d --pod "$pod" --name "$pod-app" -v "$repo:/work/repo:ro" "$perl_image" sh -c '
    cpanm -nq Mojolicious >/dev/null 2>&1 &&
    perl -I/work/repo/lib /work/repo/t/browser/app.pl prefork -w 2 -l http://127.0.0.1:3000' >/dev/null

podman run --rm --pod "$pod" -v "$here:/work/b:ro" -e BASE=http://127.0.0.1:3000 "$pw_image" sh -c '
    cp -R /work/b /tmp/b && cd /tmp/b &&
    npm install --no-save --silent playwright@1.49.0 >/dev/null 2>&1 &&
    node test.mjs'
