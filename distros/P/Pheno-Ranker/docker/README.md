# Docker

Use Docker when you want a reproducible environment with the Perl and Python dependencies preinstalled.

## Method 1: From Docker Hub

Download the latest image:

```bash
docker pull manuelrueda/pheno-ranker:latest
docker image tag manuelrueda/pheno-ranker:latest cnag/pheno-ranker:latest
```

## Method 2: Build From Dockerfile

The repository includes `docker/Dockerfile`.

Build the image from the repository root so the build context includes the full checkout:

```bash
docker build -f docker/Dockerfile -t cnag/pheno-ranker:latest .
```

For multi-architecture builds, use Buildx:

```bash
docker buildx build -f docker/Dockerfile -t cnag/pheno-ranker:latest .
```

## Run The Container

Start a detached container:

```bash
docker run -tid -e USERNAME=root --name pheno-ranker cnag/pheno-ranker:latest
```

Enter the container:

```bash
docker exec -ti pheno-ranker bash
```

The command-line executable is available at:

```text
/usr/share/pheno-ranker/bin/pheno-ranker
```

The default container user is `root`, but you can also run as `UID=1000` (`dockeruser`):

```bash
docker run --user 1000 -tid --name pheno-ranker cnag/pheno-ranker:latest
```

## Use `make`

If you prefer, use the included `makefile.docker` from the repository root:

```bash
make -f makefile.docker install
make -f makefile.docker run
make -f makefile.docker enter
```

## Mount Volumes

Containers are isolated, so mount a host directory when you need to read or write local data:

```bash
docker run -tid --volume /path/to/data:/data --name pheno-ranker-mount cnag/pheno-ranker:latest
```

One convenient pattern is to create an alias on the host:

```bash
alias pheno-ranker='docker exec -ti pheno-ranker-mount /usr/share/pheno-ranker/bin/pheno-ranker'
pheno-ranker -r /data/individuals.json -o /data/matrix.txt
```

## System Requirements

- Supported targets: `linux/amd64` and `linux/arm64`.
- Perl 5.26+ inside the image.
- At least 4 GB RAM for small examples.
- More RAM and disk are recommended for large cohort matrices.
