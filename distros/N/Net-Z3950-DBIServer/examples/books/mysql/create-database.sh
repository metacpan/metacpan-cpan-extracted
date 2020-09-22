#!/bin/sh

make insert.sql &&
mysql -u root -p < create.sql &&
mysql books < insert.sql
