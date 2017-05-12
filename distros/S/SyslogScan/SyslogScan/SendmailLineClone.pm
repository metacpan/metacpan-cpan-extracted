package SyslogScan::SendmailLineClone;

$VERSION = 0.20;
sub Version { $VERSION };

@ISA = qw( SyslogScan::SendmailLineTrans );
use strict;

sub parseContent
{
    my($self) = shift;

    # sanity-check that the required "owner" attribute was filled in
    # with a legal number
    my $attrHashRef = $$self{"attrHash"};
    if (! defined $$attrHashRef{owner})
    {
	die("No owner field in clone line %$attrHashRef");
    }
    return;
}
