
# Document with Commands to Reproduce Results Figures from the Paper

Assuming you have the executables in your `PATH`. Otherwise, substitute the executable with the full path.

## Figure 3

First, we create the file `individuals.json`:

```bash
bff-pxf-simulator -n 100 \
                  -phenotypicFeatures 1 -max-phenotypicFeatures 2  \
                  -diseases 1 -max-diseases 2 \
                  -treatments 1 -max-treatments 2 \
                  -procedures 0 -exposures 0 \
                  --random-seed 123456789
```

To create each figure, the following command needs to be executed after `Pheno-Ranker`:

```bash
Rscript ../r/heatmap.R
```

### A

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures
```

### B

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures sex
```

### C

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures sex diseases
```

### D

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures sex diseases treatments
```

## Figure 4

First, we download the file:

```bash
wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/refs/heads/main/CINECA_synthetic_cohort_EUROPE_UK1/bff/individuals.json
```

### A

```bash
pheno-ranker -r individuals.json -include-terms sex ethnicity -w weights_fig4.yaml
```

### B

```bash
pheno-ranker -r individuals.json -include-terms sex ethnicity -w weights_fig4.yaml --similarity-metric-cohort jaccard
```

## Table 1

### A

First, we create the reference cohort:

```bash
bff-pxf-simulator -n 1000 \
                  -phenotypicFeatures 2 -max-phenotypicFeatures 25 \
                  --random-seed 123456789
```

Now the patient:

```bash
bff-pxf-simulator -n 1 \
                  -phenotypicFeatures 2 -max-phenotypicFeatures 25 \
                  --random-seed 987654321 -o patient.json
```

We run `Pheno-Ranker`:

```bash
pheno-ranker -r individuals.json -t patient.json -include-terms phenotypicFeatures
```

### B

First, we create the reference cohort:

```bash
bff-pxf-simulator -n 1000 \
                  -phenotypicFeatures 3 -max-phenotypicFeatures 5 \
                  -diseases 3 -max-diseases 5 \
                  -treatments 3 -max-treatments 5 \
                  --random-seed 123456789
```

Now the patient:
```bash
bff-pxf-simulator -n 1 \
                  -phenotypicFeatures 3 -max-phenotypicFeatures 5 \
                  -diseases 3 -max-diseases 5 \
                  -treatments 3 -max-treatments 5 \
                  --random-seed 987654321 -o patient.json
```

We run `Pheno-Ranker`:

```bash
pheno-ranker -r individuals.json -t patient.json -include-terms phenotypicFeatures diseases treatments
```

## Supporting Figure 4

### A

Create cohort:

```bash
bff-pxf-simulator -n 10 \
                  -phenotypicFeatures 10 \
                  -diseases 10 \
                  -treatments 10 \
                  -procedures 10 \
                  -exposures 10 \
                  --random-seed 123456789
```

Run `Pheno-Ranker`:

```bash
pheno-ranker -r individuals.json
```


### C

Create cohort:

```bash
bff-pxf-simulator -n 100 \
                  -phenotypicFeatures 10 \
                  -diseases 10 \
                  -treatments 10 \
                  -procedures 10 \
                  -exposures 10 \
                  --random-seed 123456789
```

Run `Pheno-Ranker`:

```bash
pheno-ranker -r individuals.json
```

## Supporting Figure 5

```bash
bff-pxf-simulator -n 100 \
                  -phenotypicFeatures 2 -max-phenotypicFeatures 5 \
                  -diseases 2 -max-diseases 5 \
                  -treatments 2 -max-treatments 5 \
                  -procedures 0 -exposures 0 \
                  --random-seed 123456789
```

### A

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures diseases treatments sex
```

### B

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures diseases treatments sex -w weights_sex.yaml
```

### C

```bash
pheno-ranker -r individuals.json -include-terms phenotypicFeatures diseases treatments sex -w weights_sex_treatments.yaml
```

### D

```bash
Rscript ../r/mds.R
```

## Supporting Figure 6

Create cohort A:

```bash
bff-pxf-simulator -n 10 \
                  -diseases 1 -max-diseases 1 \
                  -o cohort_A.json \
                  --random-seed 123456789
```

Create cohort B:

```bash
bff-pxf-simulator -n 10 \
                  -diseases 2 -max-diseases 5 \
                  -o cohort_B.json \
                  --random-seed 123456789
```

### A

```bash
pheno-ranker -r cohort_A.json cohort_B.json -include-terms diseases
```

### B

```bash
pheno-ranker -r cohort_A.json cohort_B.json -include-terms diseases sex
```

### C

```bash
pheno-ranker -r cohort_A.json cohort_B.json -include-terms diseases --similarity-metric-cohort jaccard
```

### D

```bash
pheno-ranker -r cohort_A.json cohort_B.json -include-terms diseases sex --similarity-metric-cohort jaccard
```

## Supporting Figure 7

First, we download the file:

```bash
wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/refs/heads/main/CINECA_synthetic_cohort_EUROPE_UK1/bff/individuals.json
```

Now we run the utility:

```bash
bff-pxf-plot -i individuals.json
```
