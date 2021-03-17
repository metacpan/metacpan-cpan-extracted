# If you use a custom EmailSubjectTagRegex already, it's recommended to copy
# these lines into your own RT_SiteConfig.pm.

Set( $DistributionSubjectTagAllowed, qr/[a-z0-9 ._-]/i );
Set( $EmailSubjectTagRegex, qr/$EmailSubjectTagRegex(?:\s+$DistributionSubjectTagAllowed+)?/ );

# Necessary because RT_Config.pm's default is evaluated before we change the
# regex above.
Set( $ExtractSubjectTagNoMatch, qr/\[$EmailSubjectTagRegex #\d+\]/ );

# Translate distribution search strings from their canonical names,
# like Data::Dumper, to their queue name, like Data-Dumper.
#Set(%DistributionToQueueRegex,
#    'Pattern' => '::',
#    'Substitution' => '-'
#);

# Group BugTracker-specific custom fields
Set(%CustomFieldGroupings,
    'RT::Ticket' => [
        'BugTracker' => ['Severity', 'Broken in', 'Fixed in'],
    ],
);

Set(@BugTracker_CustomFieldsOnUpdate, 'Fixed in');

Set($BugTracker_SearchResultFormat, <<EOF);
    '<a href="__WebPath__/Ticket/Display.html?id=__id__">__id__</a>/TITLE:ID',
    '<b><a href="__WebPath__/Ticket/Display.html?id=__id__">__Subject__</a></b>/TITLE:Subject',
    '__Status__',
    '__CustomField.{Severity}__',
    '<small>__LastUpdatedRelative__</small>',
    '__CustomField.{Broken in}__',
    '__CustomField.{Fixed in}__'
EOF

1;
