# Non-Containerized Installation

Use this path when you want to run `pheno-ranker` directly from CPAN, GitHub, Conda, or your own Perl environment.

## System Dependencies

On Debian-based distributions, install:

```bash
sudo apt-get install cpanminus libperl-dev
```

Repository installs may also need build tools and SSL headers through the dependency chain:

```bash
sudo apt-get install build-essential libssl-dev
```

## Method 1: From CPAN

Install under `~/perl5`:

```bash
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm --notest Pheno::Ranker
pheno-ranker --help
```

To make the local Perl library persistent across shells:

```bash
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
```

To update later:

```bash
cpanm Pheno::Ranker
```

## Method 2: CPAN In A Conda Environment

This path is useful when you want an isolated environment but still want to run the non-containerized CLI.

### Step 1: Install Miniconda

The following example targets `x86_64` Linux systems:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

Close and reopen the terminal after the installer finishes.

### Step 2: Configure Channels

Set up the channels required by Bioconda:

```bash
conda config --add channels bioconda
```

It is better to install into a fresh environment to avoid dependency conflicts.

### Step 3: Create The Environment And Install

```bash
conda create -n myenv
conda activate myenv
conda install -c conda-forge gcc_linux-64 perl perl-app-cpanminus
# conda install -c bioconda perl-mac-systemdirectory   # macOS only
cpanm --notest Pheno::Ranker
pheno-ranker --help
```

Replace `myenv` with your preferred environment name.

To deactivate the environment:

```bash
conda deactivate
```

## Method 3: From GitHub

Clone the repository:

```bash
git clone https://github.com/cnag-biomedical-informatics/pheno-ranker.git
cd pheno-ranker
```

Update an existing clone:

```bash
git pull
```

Install dependencies under `~/perl5`:

```bash
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm --notest --installdeps .
bin/pheno-ranker --help
```

The repository checkout also includes the Python utilities under `utils/`.
