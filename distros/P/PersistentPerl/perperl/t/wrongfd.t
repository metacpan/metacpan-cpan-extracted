
# Bug found in 2.0 pre-release.  When the frontend was called with fd-1
# closed, it would open the perperl temp-file as fd-1, then write its
# stdout into the temp-file, corrupting it.

my $cmd = "$ENV{PERPERL} t/scripts/stdio";
my $this_file = 't/wrongfd.t';

print "1..1\n";

# DO NOT MODIFY THIS LINE - ASDFABC123

#
# First run, try to put in data that will cause courruption of the header
# in the temp-file.  Two ff's should corrupt the group_head slot number.
# If we were to write zeroes that probably wouldn't cause corruption.
#
# Probably could use a more direct test here, like reading back the file
# directly.
#
open(SAVESTDOUT, ">&STDOUT");
close(STDOUT);
open(F, "| $cmd");
print F chr(255);
close(F);
open(STDOUT, ">&SAVESTDOUT");
close(SAVESTDOUT);

# Second run should fail if bug is present
open(STDIN, "<$this_file");
open(F, "$cmd |");
my $ok = grep {/ASDFABC123/} <F>;
close(F);

print $ok ? "ok\n" : "not ok\n";
