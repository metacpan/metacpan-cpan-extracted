#!/bin/bash
# Zabbix AlertScript
# Please in AlertScriptsPath and create custom media type
GROUP_ID=$1
MSG=$2
mon-spooler.pl create -g$GROUP_ID -ttext -m"$MSG"

