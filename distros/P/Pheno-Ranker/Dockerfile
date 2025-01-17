#FROM perl:5.36-bullseye
FROM perl:stable-bullseye

# File Author / Maintainer
LABEL org.opencontainers.image.authors="Manuel Rueda <manuel.rueda@cnag.eu>"

# Set the environment variable to prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install system dependencies
RUN apt-get update && \
    apt-get -y install \
    gcc \
    unzip \
    make \
    git \
    cpanminus \
    perl-doc \
    vim \
    sudo \
    libperl-dev \
    python3-pip \
    libzbar0
#    r-base \        # (optional)
#    r-base-dev      # (optional)

# Download Pheno-Ranker
WORKDIR /usr/share/
RUN git clone https://github.com/CNAG-Biomedical-Informatics/pheno-ranker.git

# Install Perl modules
WORKDIR /usr/share/pheno-ranker
RUN cpanm --notest --installdeps .

# Install Python packages (utils/barcode)
RUN pip3 install -r requirements.txt

# Install R packages (optional)
#RUN Rscript -e "install.packages(c('pheatmap', 'ggplot2', 'ggrepel', 'dplyr', 'stringr'), repos='http://cran.rstudio.com/')"

# Add user "dockeruser"
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" dockeruser \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" dockeruser

# To change default user from root -> dockeruser
#USER dockeruser

# Get back to entry dir
WORKDIR /usr/share/pheno-ranker
