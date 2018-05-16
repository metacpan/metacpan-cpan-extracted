FROM perl:5.8

RUN apt-get update && apt-get install -y vim-tiny

COPY . .
RUN perl Makefile.PL

RUN find . -name \*.pm | xargs podchecker
RUN cpanm --installdeps .
RUN make && make test
