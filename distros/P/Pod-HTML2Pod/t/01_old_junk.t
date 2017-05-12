
# Time-stamp: "2004-12-29 18:45:04 AST"

use Test;
BEGIN { plan tests => 2 }

use Pod::HTML2Pod;
ok 1;
print "# Perl v$], Pod::HTML2Pod $Pod::HTML2Pod::VERSION\n\n";


ok Pod::HTML2Pod::convert('content' => '<h1>FOO</h1>'), '/=head1 FOO/', "Rudimentary heading conversion";

__END__

