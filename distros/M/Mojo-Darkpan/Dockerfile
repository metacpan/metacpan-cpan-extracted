ARG PERL_VERSION=5.44

FROM perl:${PERL_VERSION}-slim-threaded AS compile-image

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    build-essential curl ca-certificates \
    libssl-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm \
    | perl - install -g App::cpm

COPY cpanfile ./

RUN cpm install --global --show-build-log-on-failure

FROM perl:${PERL_VERSION}-slim-threaded AS build-image

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates git openssh-client libssl3 zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=compile-image /usr/local /usr/local

RUN useradd --system --no-create-home --home-dir /opt --shell /usr/sbin/nologin darkpan \
    && mkdir -p /opt/darkpan \
    && chown darkpan:darkpan /opt/darkpan

WORKDIR /opt

COPY --chown=darkpan:darkpan ./lib /opt/lib
COPY --chown=darkpan:darkpan ./script /opt/script

# uploaded distributions and the generated index live here
ENV DARKPAN_DIRECTORY=/opt/darkpan
VOLUME /opt/darkpan

USER darkpan
EXPOSE 3000

CMD ["perl", "script/darkpan", "--port", "3000"]

# docker build --progress plain --tag mojo-darkpan:latest .
# docker run --init -p 3000:3000 -v darkpan-data:/opt/darkpan mojo-darkpan:latest
