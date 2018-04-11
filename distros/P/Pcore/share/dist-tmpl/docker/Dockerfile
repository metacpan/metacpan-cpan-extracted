FROM <: $dockerhub_pcore_repo_id | raw :>:latest

LABEL maintainer="<: $author | raw :>"

USER root

ENV DIST_PATH="$PCORE_LIB/<: $dist_path :>"

ADD . $DIST_PATH

WORKDIR $DIST_PATH

RUN /bin/bash -c ' \

    # setup perl build env
    source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/perl-build-env.sh || echo false ) setup \

    # deploy and test distribution
    && pcore deploy --recommends --suggests \
    && pcore test -j $(nproc) \

    # cleanup perl build env
    && source <( wget -q -O - https://bitbucket.org/softvisio/scripts/raw/tip/perl-build-env.sh || echo false ) cleanup \
'

ENTRYPOINT ["bin/main.pl"]
