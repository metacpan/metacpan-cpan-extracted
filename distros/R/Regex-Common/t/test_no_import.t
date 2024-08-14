# LOAD
BEGIN { print "1..3\n"; }

use Regex::Common qw /no_defaults/;

print "ok 1\n";

print defined &Regex::Common::URL::pattern ? "not ok 2\n" : "ok 2\n";

# Make sure $; isn't modified.
print $; eq "\034" ? "ok 3" : "not ok 3";
print ' # $; eq "\034"', "\n";

__END__
