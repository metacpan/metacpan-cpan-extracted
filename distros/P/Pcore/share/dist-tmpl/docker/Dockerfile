FROM <: $dockerhub_pcore_repo_id | raw :>:latest

LABEL maintainer="<: $author | raw :>"

USER root

ENV DIST_PATH="$WORKSPACE/<: $dist_path :>"

ADD . $DIST_PATH

WORKDIR $DIST_PATH/data

RUN \
    # setup perl build env
    curl -fsSL https://bitbucket.org/softvisio/scripts/raw/master/perl-build-env.sh | /bin/bash -s -- setup \
    \
    # deploy deps
    # && dnf -y install ... \
    \
    # deploy non-CPAN deps
    # && mkdir "$WORKSPACE/pcore-cdn-static-data" \
    # && curl -fsSL https://bitbucket.org/softvisio/pcore-cdn-static-data/get/master.tar.gz | tar -C "$WORKSPACE/pcore-cdn-static-data" --strip-components=1 -xzf - \
    \
    # deploy and test distribution
    && pcore deploy --recommends --suggests \
    # && pcore crypt encrypt --force --recursive --protect \
    && pcore test -j $(nproc) \
    \
    # cleanup perl build env
    && curl -fsSL https://bitbucket.org/softvisio/scripts/raw/master/perl-build-env.sh | /bin/bash -s -- cleanup

ENTRYPOINT [ "/bin/bash", "-l", "-c", "exec ../bin/main.pl \"$@\"", "bash" ]
