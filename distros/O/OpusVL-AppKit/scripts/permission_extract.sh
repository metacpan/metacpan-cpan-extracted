#!/bin/sh

if [ $# -lt 2 ]
then
    echo Usage $0 dbname file.txt
    echo Exports a dump of the features and roles to the file specified.
    exit 1
fi

echo Roles >> $2
echo >> $2
psql $1 -c "SELECT '\"' || ar.actionpath || '\"', '[' || array_to_string(ARRAY(SELECT '\"' || r.role || '\"' FROM aclrule_role rr JOIN role r ON rr.role_id=r.id WHERE rr.aclrule_id=ar.id ), ',') || '],' FROM aclrule ar;" --field-separator " => " --quiet --no-align --pset footer | sort | grep -v '?column? => ?column?' > $2
echo >> $2
echo Features >> $2
echo >> $2
psql $1 -c "SELECT '\"' || ar.feature || '\"', '[' || array_to_string(ARRAY(SELECT '\"' || r.role || '\"' FROM aclfeature_role rr JOIN role r ON rr.role_id=r.id WHERE rr.aclfeature_id=ar.id ), ',') || '],' FROM aclfeature ar;" --field-separator " => " --quiet --no-align --pset footer | sort | grep -v '?column? => ?column?' >> $2
