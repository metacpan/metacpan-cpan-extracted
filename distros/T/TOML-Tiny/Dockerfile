FROM perl:latest

RUN mkdir /toml-tiny
WORKDIR /toml-tiny
COPY ./ ./

RUN cpanm -nq Dist::Zilla
RUN dzil authordeps --missing | cpanm -nq
RUN dzil listdeps --missing | cpanm -nq
RUN dzil test -j8
