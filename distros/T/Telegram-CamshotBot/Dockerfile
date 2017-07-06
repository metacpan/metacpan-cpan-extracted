# docker build . -t pavelsr/camshotbot

# typical Dockerfile for Mojolicious web service
# for mounting source code as volume
# require cpanfile with all dependencies in root
# if you need to minimize size you can remove ffmpeg

FROM alpine
LABEL maintainer "Pavel Serikov <pavelsr@cpan.org>"

ENV EV_EXTRA_DEFS -DEV_NO_ATFORK

RUN apk update && \
  apk add ffmpeg perl perl-io-socket-ssl perl-dbd-pg perl-dev g++ make wget curl && \
  curl -L https://cpanmin.us | perl - App::cpanminus && \
  cpanm Telegram::CamshotBot -M https://cpan.metacpan.org && \
  apk del perl-dev g++ make wget curl && \
  rm -rf /root/.cpanm/* /usr/local/share/man/*
