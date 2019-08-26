# Maintainer: Erik Huelsmann
FROM perl:5.28

COPY . /usr/src/pherkin

WORKDIR /usr/src/pherkin

RUN apt-get update && apt-get install -y libdist-zilla-perl

RUN dzil authordeps --missing | cpanm --notest
RUN dzil listdeps --missing --author | cpanm --notest
RUN cpanm --notest Clone
RUN cpanm --notest JSON::MaybeXS
RUN cpanm --notest File::Find::Rule
RUN cpanm --notest IO::Scalar
RUN rm -rf /usr/src/pherkin

