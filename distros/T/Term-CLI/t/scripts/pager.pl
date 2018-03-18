#
# Fake "pager" script.
#
# Usage: pager.pl <exitcode>
#
# Script drains STDIN and exits with <exitcode>.
#

my $status = shift @ARGV;

while (<>) { }

exit $status // 0;
