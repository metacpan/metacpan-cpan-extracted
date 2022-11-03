FROM ubuntu:20.04
WORKDIR /opt/container
ENV TZ=UTC
COPY container-startup.sh Sys-OsPackage-*.tar.gz .
RUN apt-get update && apt-get install -y tar make gcc tree perl perl-modules-5.30 cpanminus libwww-perl \
    libyaml-perl libperl-prereqscanner-notquitelite-perl libfile-sharedir-perl libfile-copy-recursive-perl \
    libtext-diff-perl
VOLUME /opt/container/logs
CMD /opt/container/container-startup.sh
