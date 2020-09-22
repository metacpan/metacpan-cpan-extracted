#!/bin/sh

make insert.sql &&
psql template1 < create.sql &&
psql resultsdb < insert.sql
