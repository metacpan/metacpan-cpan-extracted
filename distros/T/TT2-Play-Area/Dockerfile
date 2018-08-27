FROM perl:5.28

COPY cpanfile /opt/play-area/cpanfile
WORKDIR /opt/play-area

# test but don't install test deps.
ARG EXTRA_CPANM=""
RUN cpanm --test-only --installdeps . $EXTRA_CPANM && cpanm --notest --quiet --installdeps . $EXTRA_CPANM
COPY . /opt/play-area

RUN groupadd -r playarea && useradd -r -d /home/playarea -g playarea playarea
USER playarea

CMD starman --preload-app -I /opt/play-area/lib/ /opt/play-area/bin/tt2-play-area.psgi
