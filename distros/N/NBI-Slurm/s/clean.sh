#!/bin/bash
for i in NBI-Slurm*.tar.gz;
do
  echo $i
  rm "$i"
  if [[ -d "${i%.tar.gz}" ]]; then
    echo " - Directory found"
    rm -rf  "${i%.tar.gz}";
  else
    echo " - Directory not found"
  fi
done

for i in NBI-Slurm*;
do
    if [[ -d "$i" ]]; then
      echo " - Removing directory $i"
      rm -rf "$i"
    fi
done
