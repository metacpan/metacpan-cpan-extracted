FROM perl:slim-threaded-bullseye AS compile-image

RUN apt-get update
RUN apt-get update && apt-get install -y \
    curl tar build-essential \
    wget gnupg ca-certificates \
    libssl-dev libssl1.1 \
    g++ git zlib1g zlib1g-dev
    
RUN curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
    && chmod +x cpanm \
    && ./cpanm App::cpanminus

ENV PERL_CPANM_OPT --verbose --mirror https://cpan.metacpan.org --mirror-only
RUN cpanm Digest::SHA Module::Signature && rm -rf ~/.cpanm
ENV PERL_CPANM_OPT $PERL_CPANM_OPT --verify

RUN cpanm App::cpm
 
COPY cpanfile ./

RUN cpm install --global --show-build-log-on-failure

FROM debian:stable-slim AS build-image

RUN apt-get update
RUN apt-get update && apt-get install -y \
    curl tar wget ca-certificates 

COPY --from=compile-image /usr/local /usr/local
WORKDIR /opt

COPY ./lib ./lib
COPY ./script ./script

EXPOSE 3000

# docker build --progress plain --tag mojo-darkpan:latest .
# docker run -init mojo-darkpan:latest script/darkpan