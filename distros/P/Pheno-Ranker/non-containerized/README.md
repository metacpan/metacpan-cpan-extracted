# Non-Containerized Installation

Use this path when you want to run `pheno-ranker` directly from CPAN, in an isolated Conda environment, from GitHub, or in your own Perl environment.

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

## Method 2: Isolated Conda Environment

Use this option when Conda is your preferred local environment and you do not want to use Docker or modify the system Perl installation. Conda isolates the compiler and Perl dependencies; Pheno-Ranker is then installed from CPAN inside that environment. In the publication nomenclature, this remains installation path `C` rather than a separate native Conda package.

### Step 1: Install Miniconda

The following example targets `x86_64` Linux systems:

```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh
```

Close and reopen the terminal after the installer finishes.

### Step 2: Create The Environment And Install

Create a dedicated environment so that the build tools and installed modules remain separate from other projects:

```bash
conda create -n pheno-ranker \
  -c conda-forge --strict-channel-priority \
  gcc_linux-64 make perl perl-app-cpanminus
conda activate pheno-ranker
# conda install -c bioconda perl-mac-systemdirectory   # macOS only
cpanm --notest Pheno::Ranker
pheno-ranker --help
```

The command above targets `x86_64` Linux, matching the Miniconda example. Replace `pheno-ranker` with another environment name if preferred.

To deactivate the environment:

```bash
conda deactivate
```

## Method 3: From GitHub

Install the current GitHub version directly with `cpanm`:

```bash
cpanm --notest https://github.com/CNAG-Biomedical-Informatics/pheno-ranker.git
pheno-ranker --help
```

### Developer Checkout

Clone the repository only when you want to inspect the source code, run tests, use local examples, or edit the code locally:

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
