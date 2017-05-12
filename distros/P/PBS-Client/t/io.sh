#!/bin/sh

#PBS -N pbsjob.sh
#PBS -d .
#PBS -e test1.err
#PBS -o test1.out
#PBS -W stagein=in.dat
#PBS -W stageout=out.dat
#PBS -M he@where.com,she@where.com,me@where.com
#PBS -m be
#PBS -l nodes=1

pwd
