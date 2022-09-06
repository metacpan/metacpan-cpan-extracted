FROM deriv/dzil
ARG HTTP_PROXY

WORKDIR /app
# Conditional copy - we want whichever files exist, and we'd typically expect to see at least one
ONBUILD COPY aptfil[e] cpanfil[e] dist.in[i] /app/
ONBUILD RUN prepare-apt-cpan.sh \
 && dzil authordeps | cpanm -n
ONBUILD COPY . /app/
ONBUILD RUN if [ -f /app/app.pl ]; then perl -I /app/lib -c /app/app.pl; fi

RUN dzil install \
 && dzil clean \
 && git clean -fd \
 && apt purge --autoremove -y \
 && rm -rf .git .circleci

ENTRYPOINT [ "bin/myriad-start.sh" ]

