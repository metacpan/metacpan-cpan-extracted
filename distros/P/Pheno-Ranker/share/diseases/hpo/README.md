# Data Origin

[HPO Annotations](https://hpo.jax.org/data/annotations)

# Download Date

**January 25, 2025**

# Downloaded Files

I don't have a local copy of the annotation files. Please download them from the [HPO website](https://hpo.jax.org/data/annotations).

### Used: `genes_to_phenotype.txt`
### Not Used: `phenotype_to_genes.txt` (Contains Ancestors)

# Usage

```bash
perl scripts/hpo_disease_converter.pl -i genes_to_phenotype.txt -f bff
perl scripts/hpo_disease_converter.pl -i genes_to_phenotype.txt -f pxf
gzip *json
```

This will create **disease-based** reference cohorts for **OMIM** and **ORPHA** for both `BFF` and `PXF` data exchange formats.

```bash
omim.pxf.json.gz
omim.bff.json.gz
orpha.bff.json.gz
orpha.bff.json.gz
```

Each object mimics an individual, containing all the HPO ontology terms associated with a given disease.

# HPO Citation

Gargano MA, et al. The Human Phenotype Ontology in 2024: phenotypes around the world.
Nucleic Acids Res. 2024 Jan 5;52(D1):D1333-D1346.
[DOI: 10.1093/nar/gkad1005](DOI: 10.1093/nar/gkad1005)
PMID: 37953324; PMCID: PMC10767975.
