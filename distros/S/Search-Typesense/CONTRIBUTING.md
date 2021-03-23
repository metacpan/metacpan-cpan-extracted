# How to Help

If you'd improve the Perl interface to Typesense (the tests particularly need
more love), be aware that the tests assume Typesense is running on a
non-standard port, 7777, with the api key of 777.

If you use docker, you can get Typesense up and running with:

    docker run \
        -p 7777:8108 -v/tmp:/data \
        typesense/typesense:0.19.0 \
        --data-dir /data --api-key=777

We run tests on docker with a non-standard port to avoid any chance of
interfering with a live installation. I know the chances are low, but it's
still possible.
