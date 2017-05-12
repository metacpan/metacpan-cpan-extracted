FROM <: $pcore_dockerhub_namespace :>/pcore:latest

MAINTAINER <: $author :>

USER root

ENV DIST_PATH="$PCORE_LIB/<: $dist_path :>"

ADD . $DIST_PATH

WORKDIR $DIST_PATH

RUN /bin/bash -c ' \
    pcore deploy --recommends --suggests \
    && pcore test -j $(nproc) \
    && rm -rf ~/.cpanm \
'

ENTRYPOINT ["bin/main.pl"]
