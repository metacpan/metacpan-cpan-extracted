#!/bin/sh

#PBS -N pbsjob.sh
#PBS -d .
#PBS -q queue01
#PBS -W x=PARTITION:cluster01
#PBS -p 10
#PBS -l nodes=2:ppn=1
#PBS -l mem=600mb
#PBS -l pmem=200mb
#PBS -l vmem=1gb
#PBS -l pvmem=100mb
#PBS -l cput=01:30:00
#PBS -l pcput=00:10:00
#PBS -l walltime=00:30:00
#PBS -l nice=5

pwd
