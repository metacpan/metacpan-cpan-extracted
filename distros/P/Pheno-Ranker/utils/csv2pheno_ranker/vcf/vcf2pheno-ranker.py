#!/usr/bin/env python3
#
#   An utility from Pheno-Ranker to convert VCF to TSV:
#
#   Last Modified: Dec/15/2023
#
#   $VERSION taken from Pheno::Ranker
#
#   Copyright (C) 2023 Manuel Rueda - CNAG (manuel.rueda@cnag.eu)
#
#   License: Artistic License 2.0
#
#   If this program helps you in your research, please cite.

import argparse
import gzip

def process_vcf_line(line, sample_ids):
    fields = line.strip().split('\t')
    chrom, pos, _, ref, alt, *rest = fields
    variant_key = f"{chrom}_{pos}_{ref}_{alt}"  # Unique key for each variant
    genotypes = [genotype[:3] for genotype in rest[4:]]  # Process genotypes (1st-3-char)
    return variant_key, dict(zip(sample_ids, genotypes))

def main(vcf_file_path, output_file_path):
    sample_ids = []
    variant_genotypes = {}
    variant_keys = []  # To store the unique keys for each variant

    # Determine if the file is gzipped based on its extension
    open_func = gzip.open if vcf_file_path.endswith('.gz') else open

    with open_func(vcf_file_path, 'rt') as vcf_file:
        for line in vcf_file:
            if line.startswith('##'):
                continue
            elif line.startswith('#'):
                headers = line.strip().split('\t')
                sample_ids = headers[9:]  # Extract sample IDs
            else:
                variant_key, genotypes_for_variant = process_vcf_line(line, sample_ids)
                if variant_key not in variant_keys:
                    variant_keys.append(variant_key)
                for sample_id, genotype in genotypes_for_variant.items():
                    variant_genotypes.setdefault(sample_id, {})[variant_key] = genotype

    # Output results to specified output file
    with open(output_file_path, 'w') as out_file:
        out_file.write('Sample ID\t' + '\t'.join(variant_keys) + '\n')
        for sample_id in sample_ids:
            genotypes = [variant_genotypes[sample_id].get(key, '.') for key in variant_keys]
            out_file.write(sample_id + '\t' + '\t'.join(genotypes) + '\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process a VCF file.')
    parser.add_argument('-i', '--input', required=True, help='Input VCF file (can be gzipped)')
    parser.add_argument('-o', '--output', default='output.tsv', help='Output file path (default: output.tsv)')
    args = parser.parse_args()
    main(args.input, args.output)
