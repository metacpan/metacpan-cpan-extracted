#!/bin/bash

set -eux

cd $(dirname $0) ; CWD=$(pwd)

SOURCE_PACKAGE='https://github.com/CycloneDX/specification/archive/refs/heads/master.zip'
SOURCE_DIR='specification-master/tools/src/test/resources'
SCHEMA_VERSIONS=('1.7' '1.6' '1.5' '1.4' '1.3' '1.2')

TEMP_DIR="$(mktemp -d)"
LOCAL_PACKAGE="$TEMP_DIR/source_package.zip"

wget -O "$LOCAL_PACKAGE" "$SOURCE_PACKAGE"

for SCHEMA_VERSION in ${SCHEMA_VERSIONS[@]}; do
  unzip -d "$TEMP_DIR" "$LOCAL_PACKAGE" "$SOURCE_DIR/$SCHEMA_VERSION/*"
  rm -rf "$CWD/$SCHEMA_VERSION"
  mkdir -p "$CWD/$SCHEMA_VERSION"
  cp -rf "$TEMP_DIR/$SOURCE_DIR/$SCHEMA_VERSION/"*.json "$CWD/$SCHEMA_VERSION/" || true
done

rm -rf "${TEMP_DIR:?}"
