FROM softvisio/node:latest AS build

WORKDIR /var/local/build/app

RUN yarn-build

FROM <: $dockerhub_pcore_repo_id | raw :>:latest

LABEL maintainer="<: $author | raw :>"

USER root

ENV DIST_PATH="$WORKSPACE/<: $dist_path :>"

ADD . $DIST_PATH

WORKDIR $DIST_PATH/data

RUN rm -rf $DIST_PATH/app
COPY --from=build /var/local/build/app/dist $DIST_PATH/app/dist

RUN \
    # setup perl build env
    curl -fsSL https://bitbucket.org/softvisio/scripts/raw/master/env-build-perl.sh | /bin/bash -s -- setup \
    \
    # deploy deps
    && dnf -y install nginx-mainline \
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
    && curl -fsSL https://bitbucket.org/softvisio/scripts/raw/master/env-build-perl.sh | /bin/bash -s -- cleanup

ENTRYPOINT [ "/bin/bash", "-l", "-c", "exec ../bin/main.pl \"$@\"", "bash" ]
