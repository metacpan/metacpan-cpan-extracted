#!/bin/bash
set -e

# Start MySQL server
/docker-entrypoint.sh mysqld &

# Wait for MySQL to start
until mysqladmin ping -h localhost --silent; do
    sleep 1
done

# Create database
mysql -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE"

# Create table
mysql -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" $MYSQL_DATABASE < /docker-entrypoint-initdb.d/mysql.sql

# Stop MySQL server
mysqladmin -h localhost -u root -p"$MYSQL_ROOT_PASSWORD" shutdown

exec "$@"
