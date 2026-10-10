# Quick-Start Data

These files provide a small, tested patient-matching example:

- `individuals.json`: a 36-record BFF reference cohort.
- `patient.json`: one BFF target patient.

After installing Pheno-Ranker, run:

```bash
pheno-ranker -r individuals.json -t patient.json -o rank.txt
```

The command creates `rank.txt` with the reference records ranked against the target patient.
