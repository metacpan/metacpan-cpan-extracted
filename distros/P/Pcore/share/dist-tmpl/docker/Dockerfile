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
    # && yum -y install ... \
    \
    # deploy non-CPAN deps
    # && mkdir "$PCORE_LIB/pcore-cdn-static-data" \
    # && wget -q -O - https://bitbucket.org/softvisio/pcore-cdn-static-data/get/tip.tar.gz | tar -C "$PCORE_LIB/pcore-cdn-static-data" --strip-components=1 -xzf - \
    \
    # deploy and test distribution
    && pcore deploy --recommends --suggests \
    # && pcore crypt encrypt --force --recursive \
    && pcore test -j $(nproc) \
    \
    # cleanup perl build env
    && source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/perl-build-env.sh || echo false ) cleanup \
'

ENTRYPOINT ["../bin/main.pl"]
