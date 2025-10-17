# this is the Docker base image for Perl projects with cpanminus, local::lib, Dist::Zilla, and Perl::Types
# v0.100_000

# DEV NOTE: prefer "perl" upstream Docker image over "perldocker/perl-tester", due to more updates & better team
# https://hub.docker.com/_/perl
FROM perl:stable-slim-bookworm

# include metadata in this Docker base image, to be checked by subsequent Docker images built on top of this one;
# compute metadata once, then store in a file that child Docker images and scripts can read
RUN PERL_VER="$(perl -MConfig -e 'print $Config{version}')" \
 && PERL_ARCH="$(perl -MConfig -e 'print $Config{archname}')" \
 && echo "Perl in base: $PERL_VER $PERL_ARCH" \
 && printf '%s\n' \
      "IO_LINUX_PERL_BASE=1" \
      "IO_LINUX_PERL_PERL_VERSION=$PERL_VER" \
      "IO_LINUX_PERL_PERL_ARCHNAME=$PERL_ARCH" \
      > /usr/local/share/linux_perl_base.env

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
LABEL io.linux-perl.base="1" \
      org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.licenses="${OCI_LICENSES}" \
      org.opencontainers.image.description="${OCI_DESCRIPTION}"

# install the following:
# system-wide C/C++ dependencies, including Perl::Types dependencies libc, SSL, zlib, GMP, GSL;
# system-wide cpanminus, to be self-upgraded below;
# system-wide Python dependencies;
# gosu, used by entrypoint script
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    make \
    gcc \
    g++ \
    git \
    pkgconf \
    libc6-dev \
    libssl-dev \
    zlib1g \
    zlib1g-dev \
    libgmp10 \
    libgmpxx4ldbl \
    libgmp-dev \
    libgsl-dev \
    gsl-bin \
    cpanminus \
    libpython3.11-dev \
    python3-full \
    python3-pip \
    python3-venv \
    ruby \
    ruby-bundler \
    ruby-dev \
    gosu && \
    rm -rf /var/lib/apt/lists/*

# install system-wide Node.js & npm dependencies,
# default to Node.js v22 (from NodeSource) in order to run markdownlint-cli2;
# DEV NOTE: normal apt repositories have old versions, NodeSource repository requires hard-coding major version,
# will have to manually update when markdownlint-cli2 version requirements change
ARG NODEJS_MAJOR_VERSION=22
RUN set -eux; \
    apt-get update; \
    apt-get install -y curl ca-certificates gnupg; \
    curl -fsSL "https://deb.nodesource.com/setup_${NODEJS_MAJOR_VERSION}.x" | bash -; \
    apt-get install -y nodejs; \
    node -v && npm -v

# install Markdown linter via npm & smoke test; append "|| true" to avoid non-0 return value
RUN npm install --global markdownlint-cli2@latest && markdownlint-cli2 --help || true

# build args to set non-root username, along with default UID/GID which will be modified by the entrypoint script
ARG USER=perluser
ARG UID=1000
ARG GID=1000

# create non-root user
RUN groupadd -g ${GID} ${USER} \
  && useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# upgrade existing system-wide cpanminus to latest from CPAN
RUN cpanm --self-upgrade

# local::lib for the user, persistently exported
ENV LOCAL_LIB=/home/${USER}/perl5
ENV PATH="${LOCAL_LIB}/bin:${PATH}"
ENV PERL5LIB="${LOCAL_LIB}/lib/perl5"
ENV PERL_LOCAL_LIB_ROOT="${LOCAL_LIB}"
ENV PERL_MB_OPT="--install_base=\"${LOCAL_LIB}\""
ENV PERL_MM_OPT="INSTALL_BASE=${LOCAL_LIB}"
ENV PERL_MM_USE_DEFAULT=1
ENV PERL_CPANM_OPT="--verbose --notest --skip-satisfied --local-lib=${LOCAL_LIB}"

# switch to non-root for all subsequent steps, except where specified
USER ${USER}
WORKDIR /app

# install local::lib & Dist::Zilla from CPAN
RUN cpanm local::lib Dist::Zilla

# copy minimal files first, for better Docker layer cache
COPY --chown=${UID}:${GID} debianfile cpanfile pythonfile rubyfile ./

# install project-specific Debian dependencies using `apt-get`,
# accepting as input our custom-named 'debianfile' Debian dependency specification file;
# use `test` to check if the 'debianfile' exists and is not empty;
# if the file is valid, then use `sed` to read its contents and filter out comments,
# use `xargs` to pass the package names to `apt-get` for installation, and
# clean up the apt cache to minimize the final Docker image size;
# run all commands as root then switch back to normal user
USER root
RUN test -s debianfile && sed 's/#.*//' debianfile | xargs apt-get install --no-install-recommends -y && rm -rf /var/lib/apt/lists/*
USER ${USER}

# install all Perl dependencies declared in 'cpanfile':
# developers AKA authors (Dist::Zilla plugins & author test deps), configure (Alien or other build-only requirements),
# build (normal requirements), and test (Test or Test2 etc);
# DEV NOTE: with all dependencies listed in 'cpanfile', this command completely replaces
# both `dzil authordeps | cpanm` and `dzil listdeps | cpanm`, and thereby removed tons of
# Dist::Zilla plugin cruft in this RUN command, which created fake '.git' & 'Changes' & main module etc;
# however there is no easy way to use `cpanm` to show the dependencies without installing, so we will just install
RUN test -s cpanfile && cpanm --notest --installdeps . --with-develop --with-configure

# activate Python virtual environment & install Python dependencies from PyPI using Python's `pip` package manager,
# accepting as input our custom-named 'pythonfile' Python dependency specification file;
# use `.` command because we are in the old `/bin/sh` Bourne shell by default, instead of Bash-only `source` command;
# DEV NOTE: disable the 2 following lines if your project does not have any Python dependencies
RUN test -s pythonfile && python3 -m venv /app/python-venv && . /app/python-venv/bin/activate && pip install -U pip && pip install --requirement pythonfile
# if distributions were installed, the new path will exist; if not, the shell will simply ignore it
ENV PATH="/app/python-venv/bin:${PATH}"

# install Ruby dependencies to the '/app/ruby-gems' directory, using Ruby's `gem` package manager,
# accepting as input our custom-named 'rubyfile' Ruby dependency specification file;
# Ruby is configured system-wide to install and find gems in '/app/ruby-gems', by setting this directory
# as the value of the "GEM_HOME" and "GEM_PATH" environment variables respectively;
# DEV NOTE: disable the 4 following lines if your project does not have any Ruby dependencies
ENV GEM_HOME=/app/ruby-gems
ENV GEM_PATH=/app/ruby-gems
RUN test -s rubyfile && gem install --file rubyfile
# if distributions were installed, the new path will exist; if not, the shell will simply ignore it
ENV PATH="/app/ruby-gems/bin:${PATH}"

# copy the rest of the project
COPY --chown=${UID}:${GID} . .

# switch to root user to copy & run the entrypoint script
USER root

# as root user, copy the entrypoint script from the repository into the Docker image
COPY docker/entrypoint_set_uid_gid_from_host.sh /usr/local/bin/entrypoint_set_uid_gid_from_host.sh
RUN chmod +x /usr/local/bin/entrypoint_set_uid_gid_from_host.sh

# use our special UID-and-GID-changing script as Docker image entrypoint;
# run a developer-friendly bash shell as the default command after entrypoint script finishes
ENTRYPOINT ["/usr/local/bin/entrypoint_set_uid_gid_from_host.sh"]
CMD ["bash"]
