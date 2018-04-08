FROM alpine
COPY . /src/
# https://bugs.alpinelinux.org/issues/7737
RUN set -ex -o pipefail; \
    apk upgrade -U; \
    apk add \
        bash \
        ca-certificates \
        gcc \
        make \
        musl-dev \
        patch \
        perl \
        perl-dev \
        perl-doc \
        procps \
        tar \
        wget; \
    ln -nsf /bin/pgrep /bin/pkill /usr/bin/; \
    wget https://cpanmin.us -q -O - | perl - App::cpanminus; \
    cpanm ./src/; \
    apk del \
        ca-certificates \
        gcc \
        make \
        musl-dev \
        perl-dev \
        perl-doc \
        wget; \
    rm -f /var/cache/apk/*; \
    rm -rf /src/
