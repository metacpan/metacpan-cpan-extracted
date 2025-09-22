# syntax=docker/dockerfile:1.6
# the above is a parser directive that tells the Docker builder, specifically BuildKit,
# which version of the Dockerfile syntax to use; this allows the builder to use the
# latest features and bug fixes for the Dockerfile syntax without requiring an update
# to the underlying Docker Engine

# this is the Docker application image that is built on top of the Docker base image;
# do not provide hard-coded registry/project for Docker base image,
# GitLab CI or user must pass "BASE_IMAGE" explicitly
ARG BASE_IMAGE=base:dev  # safe local default, must exist locally
FROM ${BASE_IMAGE}

# optional configuration settings, can be overridden via `--build-arg`
ARG VERIFY_BASE=1
ARG STRICT_PERL_MATCH=1
ENV VERIFY_BASE=$VERIFY_BASE
ENV STRICT_PERL_MATCH=$STRICT_PERL_MATCH

# optional env vars for CI builds only, ignored for local builds;
# passed in from '.gitlab-ci.yml' via `docker build --build-arg OCI_FOO="$CI_FOO"`
ARG OCI_TITLE="[UNDEFINED]"
ARG OCI_VERSION="[UNDEFINED]"
ARG OCI_REVISION="[UNDEFINED]"
ARG OCI_SOURCE="[UNDEFINED]"
ARG OCI_CREATED="[UNDEFINED]"
ARG OCI_LICENSES="[UNDEFINED]"
ARG OCI_DESCRIPTION="[UNDEFINED]"

# static label for introspection, dynamic values can't be injected here,
# keep the LABEL keys as the OCI standard names
LABEL \
  org.opencontainers.image.title="${OCI_TITLE}" \
  org.opencontainers.image.version="${OCI_VERSION}" \
  org.opencontainers.image.revision="${OCI_REVISION}" \
  org.opencontainers.image.source="${OCI_SOURCE}" \
  org.opencontainers.image.created="${OCI_CREATED}" \
  org.opencontainers.image.licenses="${OCI_LICENSES}" \
  org.opencontainers.image.description="${OCI_DESCRIPTION}"

# check to ensure correct Docker base image is provided, using `verify_base.sh` script from repository
COPY docker/verify_base.sh /usr/local/bin/verify_base.sh
RUN chmod +x /usr/local/bin/verify_base.sh \
 && /usr/local/bin/verify_base.sh

# match the non-root username used by the Docker base image
ARG USER=perluser

# build & stage our Perl distribution here so CI can copy it out as an artifact
ENV BUILD_OUT=/tmp/_build-dir

# the following 3 environmental variables are used by Perl::Config & Perl::Types & Perl::Compiler;
# feel free to use them in your own code as well
ENV PERL_VERBOSE=1
ENV PERL_DEBUG=1
ENV PERL_WARNINGS=1

# build as the non-root user
USER ${USER}
WORKDIR /app

# copy project files in a cache-friendly order,
# with 'cpanfile' & 'dist.ini' first because they change less often than the rest of the tree
COPY --chown=${USER}:${USER} cpanfile dist.ini ./

# copy the rest of the project files
COPY --chown=${USER}:${USER} . .

# access the host's real (not fake) '.git' directory via a BuildKit bind mount,
# so Dist::Zilla's Git plugins can work properly during `dzil build`;
# use `git config` to mark '/app' directory as safe to be owned
# by a different UID than USER to avoid the following error...
# fatal: detected dubious ownership in repository at '/app';
# build the distribution and keep a copy in "BUILD_OUT" for GitLab CI to extract as artifact
RUN --mount=type=bind,from=gitctx,source=.git,target=/app/.git,readonly \
    git config --global --add safe.directory /app && \
    dzil build --in ${BUILD_OUT} && \
    cpanm ${BUILD_OUT}

# switch to root user to run the entrypoint script
USER root

# Docker "ENTRYPOINT" & "CMD" are inherited from the Docker base image
