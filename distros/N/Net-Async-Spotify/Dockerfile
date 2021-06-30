FROM perl:5.26

COPY . /opt/app
WORKDIR /opt/app

RUN echo "updating apt and installing cpan deps" \
 && apt-get -y -q update \
 && cpanm -n --installdeps . \
 && rm -rf ~/.cpanm 

RUN echo "installing Net::Async::Spotify from local" \
 && dzil install \
 && dzil clean \
 && git clean -fd

ENTRYPOINT ["spotify-cli.pl", "-w"]
