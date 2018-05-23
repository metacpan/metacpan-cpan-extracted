FROM <: $dockerhub_pcore_repo_id | raw :>:latest

LABEL maintainer="<: $author | raw :>"

USER root

ENV DIST_PATH="$PCORE_LIB/<: $dist_path :>"

ADD . $DIST_PATH

WORKDIR $DIST_PATH/data

RUN /bin/bash -c ' \
    \
    # setup perl build env
    source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/perl-build-env.sh || echo false ) setup \
    \
    # deploy nginx
    && source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/install-nginx.sh || echo false ) \
    \
    # deploy non-CPAN deps
    && mkdir "$PCORE_LIB/pcore-share-www/" \
    && wget -q -O - https://bitbucket.org/softvisio/pcore-share-www/get/latest.tar.gz | tar -C "$PCORE_LIB/pcore-share-www/" --strip-components=1 -xzf - \
    \
    && mkdir "$PCORE_LIB/pcore-share-ext_v6_2_0/" \
    && wget -q -O - https://bitbucket.org/softvisio/pcore-share-ext_v6_2_0/get/latest.tar.gz | tar -C "$PCORE_LIB/pcore-share-ext_v6_2_0/" --strip-components=1 -xzf - \
    \
    # deploy and test distribution
    && pcore deploy --recommends --suggests \
    && pcore test -j $(nproc) \
    \
    # cleanup perl build env
    && source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/perl-build-env.sh || echo false ) cleanup \
'

ENTRYPOINT ["../bin/main.pl"]
