#!/bin/sh
export MOJO_MODE=development
export MOJO_LOG_LEVEL=debug
export QX_SRC_MODE=1
export QX_SRC_PATH=$(pwd)/$(dirname $0)/../frontend/compiled/source
exec `dirname $0`/<%= ${filename} %>.pl prefork --listen 'http://*:<%= int(rand()*5000+3024) %>'
