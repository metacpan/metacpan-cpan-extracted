# Docker

Use Docker when you want a reproducible environment with the Perl and Python dependencies preinstalled.

## Method 4: From Docker Hub

Download the latest image:

```bash
docker pull manuelrueda/pheno-ranker:latest
docker image tag manuelrueda/pheno-ranker:latest cnag/pheno-ranker:latest
```

## Method 5: With Dockerfile

The repository includes `docker/Dockerfile`.

Build the image from the repository root so the build context includes the full checkout:

```bash
docker build -f docker/Dockerfile -t cnag/pheno-ranker:latest .
```

For multi-architecture builds, use Buildx:

```bash
docker buildx build -f docker/Dockerfile -t cnag/pheno-ranker:latest .
```

## Run Pheno-Ranker

Run each analysis in the foreground and mount the current directory so Pheno-Ranker can read local inputs and write its results back to the host:

```bash
docker run --rm \
  --volume "$PWD:/data" \
  --workdir /data \
  cnag/pheno-ranker:latest \
  /usr/share/pheno-ranker/bin/pheno-ranker \
  -r individuals.json -t patient.json -o rank.txt
```

The command displays progress and errors in the terminal, then removes the container when it finishes. A successful run creates `rank.txt` in the current directory. Replace the final line with the Pheno-Ranker arguments required for your analysis.

The image runs as `root` by default. On Linux, add `--user "$(id -u):$(id -g)"` to keep output files owned by your current user:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "$PWD:/data" \
  --workdir /data \
  cnag/pheno-ranker:latest \
  /usr/share/pheno-ranker/bin/pheno-ranker \
  -r individuals.json -t patient.json -o rank.txt
```

## Interactive Container (Optional)

Use a named, detached container when you want to inspect the image or run several commands in the same environment:

```bash
docker run -tid \
  --volume "$PWD:/data" \
  --workdir /data \
  --name pheno-ranker \
  cnag/pheno-ranker:latest
docker exec -ti pheno-ranker bash
```

The command-line executable is available at `/usr/share/pheno-ranker/bin/pheno-ranker`. You can invoke it repeatedly from the host:

```bash
docker exec -i pheno-ranker \
  /usr/share/pheno-ranker/bin/pheno-ranker \
  -r individuals.json -t patient.json -o rank.txt
```

Remove the named container when it is no longer needed:

```bash
docker rm -f pheno-ranker
```

The image also includes `dockeruser` with `UID=1000`. To use it, add `--user 1000:1000` to the initial `docker run` command.

## Use `make`

The included `makefile.docker` builds and manages an interactive container from the repository root:

```bash
make -f makefile.docker install
make -f makefile.docker run
make -f makefile.docker enter
```

## System Requirements

- Supported targets: `linux/amd64` and `linux/arm64`.
- Perl 5.26+ inside the image.
- At least 4 GB RAM for small examples.
- More RAM and disk are recommended for large cohort matrices.
