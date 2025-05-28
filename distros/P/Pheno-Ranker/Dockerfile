FROM perl:stable-bullseye

LABEL org.opencontainers.image.authors="Manuel Rueda <manuel.rueda@cnag.eu>"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
# Ensure that system sbin directories are in PATH
ENV PATH="/usr/local/sbin:/usr/sbin:/sbin:${PATH}"

# Override ldconfig to prevent segfaults under QEMU
RUN ln -sf /bin/true /sbin/ldconfig

# Update and install all system dependencies in one command
RUN apt-get update && \
    apt-get install -y \
        libc-bin \
        gcc \
        unzip \
        make \
        git \
        cpanminus \
        perl-doc \
        vim \
        sudo \
        libgsl-dev \
        libjson-xs-perl \
        libperl-dev \
        python3-pip \
#    r-base \        # (optional)
#    r-base-dev      # (optional)
        libzbar0 && \
    rm -rf /var/lib/apt/lists/*

# Clone the Pheno-Ranker repository
WORKDIR /usr/share/
RUN git clone https://github.com/CNAG-Biomedical-Informatics/pheno-ranker.git

# Remove the .git folder to save space and avoid shipping VCS data
RUN rm -rf pheno-ranker/.git

# Install Perl and Python dependencies
WORKDIR /usr/share/pheno-ranker
RUN cpanm --notest --installdeps .

# Install Python packages (utils/barcode)                                                          
RUN pip3 install -r requirements.txt

# Install R packages (optional)
#RUN Rscript -e "install.packages(c('pheatmap', 'ggplot2', 'ggrepel', 'dplyr', 'stringr'), repos='http://cran.rstudio.com/')"

# Create user "dockeruser" with UID and GID 1000 by default
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" dockeruser && \
    useradd --create-home --no-log-init -u "${UID}" -g "${GID}" dockeruser

# To change default user from root -> dockeruser
#USER dockeruser
