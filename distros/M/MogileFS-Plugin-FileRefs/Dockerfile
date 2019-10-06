FROM perl:5.20
RUN apt-get update
RUN apt-get install -y libmysqlclient-dev
RUN cpanm --notest DBD::mysql Dist::Zilla
ENV MOGTEST_DBHOST=database
ENV MOGTEST_DBUSER=root
ENV MOGTEST_DBPASS=test
ENV MOGTEST_DBNAME=test
COPY . /usr/src/perl-MogileFS-Plugin-FileRefs
WORKDIR /usr/src/perl-MogileFS-Plugin-FileRefs
RUN dzil authordeps --missing | cpanm --notest
RUN dzil listdeps --missing | cpanm --notest
ENTRYPOINT perl -Ilib t/filerefs.t

