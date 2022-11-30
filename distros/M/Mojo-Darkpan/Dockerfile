FROM rshingleton/alpine-perl:5.36.0 AS build-image
# v1.0
RUN apk update && apk upgrade && apk add --no-cache \
        build-base \
        curl \
        wget \
        gcc \
        gnupg \
        make \
        openssl \
        openssl-dev \
        tar \
        zlib \
        zlib-dev \
        g++ \
        ca-certificates \
    && rm -rf /var/cache/apk/*

    # curl tar build-essential \
    # wget gnupg ca-certificates \
    # libssl-dev libssl1.1 \
    # g++ git zlib1g zlib1g-dev
    
COPY cpanfile ./

RUN cpm install --global --show-build-log-on-failure

FROM alpine:latest AS runtime-image

ENV PATH="/opt/perl/bin:${PATH}"

# Copy the base Perl installation from the build-image
COPY --from=build-image /opt/perl /opt/perl

RUN apk update && apk upgrade && apk add --no-cache \
        curl \
        openssl \
        openssl-dev \
        openssh \
        wget \
        git \
        ca-certificates \
    && rm -rf /var/cache/apk/*    

WORKDIR /app

ARG VER=1.0

COPY . .

EXPOSE 3000

# docker build --progress plain --tag mojo-darkpan:latest .
# docker run --init -p 3000:3000 mojo-darkpan:latest script/darkpan