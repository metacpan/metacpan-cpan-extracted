#!/bin/sh
# build a container to test Sys::OsPackage on various OS environments
# for sniffing out OS configurations that break when reported by CPAN Testers

# function to print error message and exit
die() {
    echo "host error: $*" >&2
    exit 1
}

# build container
build() {
    # check if OS name has a Containerfile (Podman's equivalent of a Dockerfile) in this directory
    containerfile="$osname.containerfile"

    # verify container file exists
    if [ ! -f "$containerfile" ]
    then
        die "OS name $osname does not have a Containerfile"
    fi

    # verify source tarball is available
    if [ -f ../../dist.ini ] && grep --quiet '^\s*name\s*=\s*Sys-OsPackage\s*$' ../../dist.ini
    then
        # This is being run from the source tree. Get a new tarball.
        rm -f Sys-OsPackage-*.tar.gz
        echo building...
        (cd ../.. && dzil build)
        # shellcheck disable=SC2012
        cp -p "$(ls -t ../../Sys-OsPackage-*.tar.gz | head -1)" .
    else
        # shellcheck disable=SC2012
        num_tarballs="$(ls -1 Sys-OsPackage-*.tar.gz | wc -l)"
        if [ "$num_tarballs" -eq 0 ]
        then
            die "Sys-OsPackage tarball file required: not found"
        fi
    fi

    ( $podman build --file "$containerfile" --tag "$imagename:$timestamp" \
        && $podman tag "$imagename:$timestamp" "$imagename:latest" ) \
            || die build failed
}

# run container
run() {
    # check if OS name has an image built. If not, build it.
    if ! $podman image exists "$imagename:latest"
    then
        build_container || die "build_container failed on $osname"
    fi

    # run container
    mkdir --parents "logs/$timestamp/.cpan" "logs/$timestamp/.cpanm"
    chmod ug=rwx,ug-s,o= logs "logs/$timestamp" "logs/$timestamp/.cpan" "logs/$timestamp/.cpanm"
    $podman run -it --label="sys-ospkg-test=1" --env="SYS_OSPKG_TIMESTAMP=$timestamp" \
        --mount "type=bind,src=logs,dst=/opt/container/logs,relabel=shared,readonly=false" \
        "$imagename:latest" \
        || die run failed
}

# clean up environment
clean() {
    # clear out logs
    echo clean logs...
    rm -rf logs/2[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]

    # clean out containers and images
    echo clean containers...
    # shellcheck disable=SC2046
    containers="$($podman container ls --all --quiet --filter="label=sys-ospkg-test")"
    if [ -n "$containers" ]
    then
        # shellcheck disable=SC2086
        $podman container rm $containers
    fi
    echo clean images...
    # shellcheck disable=SC2046
    images="$($podman image ls --quiet \*-sys-ospkg-test)"
    if [ -n "$images" ]
    then
        # shellcheck disable=SC2086
        $podman image untag $images
        # shellcheck disable=SC2086
        $podman image rm --force $images
    fi
}

# podman is required for this script to work
podman="$(which podman)"
if [ -z "$podman" ]
then
    die "podman required but not found - fix PATH if it's already installed"
fi

# use command name to decide on build or run
cmd="$1"
osname="$2"
timestamp=$(date '+%Y-%m-%d-%H-%M-%S')
imagename="$osname-sys-ospkg-test"
case "$cmd" in
    build) build;;
    run) run;;
    clean) clean;;
    *) die "unrecognized command name $0";;
esac
exit 0

