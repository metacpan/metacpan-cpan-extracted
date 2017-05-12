use Test::More tests => 3;
use Template;
use_ok("Template::Plugin::XSLT");

my $t = new Template;

my $output;
ok(
    $t->process("t/test", {
            xml => "<foo></foo>", # Don't blame me, it's in XSLT examples
        }, \$output)
, "Processing OK") or
print "# ".$t->error."\n";
is($output, <<EOF, "Output OK");
Before 
<html><body>fooooo!<p> You knew the magic word! </p>
</body></html>

After
EOF
