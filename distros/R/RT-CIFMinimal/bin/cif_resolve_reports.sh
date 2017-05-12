BIN=$0
RTCRON="/opt/rt3/bin/rt-crontool"
VERBOSE=$1
LOCK="/var/run/cif_resolve_reports.sh.run"

if [ -f $LOCK ]; then
  echo 'already running, bailing out'
  exit
fi

echo `date` > $LOCK

REPORTS="ipv4-addr ipv4-net domain url"

for REPORT in $REPORTS; do
    $RTCRON --search RT::Search::ActiveTicketsInQueue --search-arg "Incident Reports" \
        --condition RT::Condition::CIFMinimal_Stale --condition-arg "$REPORT" \
        --action RT::Action::CIFMinimal_SetStatus --action-arg "resolved" \
        --transaction first $VERBOSE
done

rm $LOCK
