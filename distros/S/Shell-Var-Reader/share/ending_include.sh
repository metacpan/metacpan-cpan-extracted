#!/bin/sh

if [ ! -z "$SAGAN_INSTANCES" ]; then
        SAGAN_INSTANCES=`echo "$SAGAN_INSTANCES" | sed 's/\ //g' | sed 's/,,*/,/g' | sed 's/^,,*//g' | sed 's/,,*$//g'`
        SAGAN_COUNT=`echo "$SAGAN_INSTANCES" | awk '{gsub(/,/,"\n")}1' | grep -v -E '^$' | sort | uniq | grep -v honeypot | wc -l | sed 's/^ *//'`
        CLIENT_STATS_ENABLE=1
        SAGAN_INSTANCES=`echo "$SAGAN_INSTANCES" | awk '{gsub(/,/,"\n")}1' | grep -v -E '^$' | sort | uniq| paste -s -d, `
        if [ "$NO_MEER_CS" -ge 1 ]; then
                MEER_COUNT="$SAGAN_COUNT"
                CLIENT_STATS_ENABLE=0
        else
                MEER_COUNT=`expr "$SAGAN_COUNT" + 1`
        fi
fi

if [ ! -z "$SURICATA_INSTANCES" ]; then
        SURICATA_INSTANCES=`echo "$SURICATA_INSTANCES" | sed 's/\ //g' | sed 's/,,*/,/g' | sed 's/^,,*//g' | sed 's/,,*$//g'`
        SURICATA_COUNT=`echo $SURICATA_INSTANCES | awk '{gsub(/,/,"\n")}1' | grep -v -E '^$' | sort | uniq | grep -v honeypot | wc -l | sed 's/^ *//'`
        MEER_COUNT=`expr "$MEER_COUNT" + "$SURICATA_COUNT"`
fi

SAGAN_OR_SURICATA=0
if [ "$SURICATA_COUNT" -ge 1 ]; then
    SAGAN_OR_SURICATA=1
fi
if [ "$SAGAN_COUNT" -ge 1 ]; then
    SAGAN_OR_SURICATA=1
fi

