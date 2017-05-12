#!/bin/zsh
MODULES=$(grep '^package' lib/**/*pm|grep -o '[^ ]\+$' |grep -o '[^;]\+')
# echo $MODULES
MODULE_OPT=""
for mod in $(echo $MODULES);do
    MODULE_OPT="$MODULE_OPT -M $mod"
done
echo $MODULE_OPT
