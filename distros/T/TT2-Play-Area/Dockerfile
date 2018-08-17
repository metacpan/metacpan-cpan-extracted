FROM perl:5.26

COPY cpanfile /opt/play-area/cpanfile
WORKDIR /opt/play-area
RUN cpanm --installdeps .
COPY . /opt/play-area

CMD starman --preload-app -I /opt/play-area/lib/ /opt/play-area/bin/tt2-play-area.psgi
