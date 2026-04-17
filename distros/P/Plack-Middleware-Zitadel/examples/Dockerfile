FROM perl:5.40-slim

WORKDIR /app

COPY cpanfile .
RUN cpanm --installdeps . --notest && cpanm --notest Starman

COPY lib ./lib
COPY examples/proxy.psgi ./proxy.psgi

ENV PLACK_ENV=production
EXPOSE 5000

CMD ["plackup", "-Ilib", "proxy.psgi", "-p", "5000", "-s", "Starman"]
