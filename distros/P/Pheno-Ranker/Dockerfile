FROM perl:5.36-bullseye

# File Author / Maintainer
LABEL maintainer Manuel Rueda <manuel.rueda@cnag.eu>

# Install Linux tools
RUN apt-get update && \
    apt-get -y install gcc unzip make git cpanminus perl-doc vim sudo libperl-dev

# Download Pheno-Ranker
WORKDIR /usr/share/
RUN git clone https://github.com/CNAG-Biomedical-Informatics/pheno-ranker.git

# Install Perl modules
WORKDIR /usr/share/pheno-ranker
RUN cpanm --notest --installdeps .

# Add user "dockeruser"
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" dockeruser \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" dockeruser

# To change default user from root -> dockeruser
#USER dockeruser

# Get back to entry dir
WORKDIR /usr/share/pheno-ranker
