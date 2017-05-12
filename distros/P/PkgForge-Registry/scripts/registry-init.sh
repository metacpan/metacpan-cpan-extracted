#!/bin/bash

set -ue

# This script sets up the pkgforge database and owner if you are
# starting from scratch. This should, normally, be run as the postgres
# user.

createuser --no-createrole --no-createdb --no-superuser pkgforge_admin
createuser --no-createrole --no-createdb --no-superuser pkgforge_incoming
createuser --no-createrole --no-createdb --no-superuser pkgforge_builder
createuser --no-createrole --no-createdb --no-superuser pkgforge_web

createdb --owner pkgforge_admin pkgforge
createlang plpgsql pkgforge

