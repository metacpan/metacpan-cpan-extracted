FROM graphqlperl/mojoliciousplugin-prereq:latest

# Copy the current directory contents into the container
ADD . /opt/m-p-gql/

RUN cd /opt/m-p-gql \
  && perl Makefile.PL \
  && make test install \
  && perl5.26.1 -MMojolicious::Plugin::GraphQL -e0 \
  && true
