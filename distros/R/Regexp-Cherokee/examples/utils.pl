#!/usr/bin/perl -w

use Regexp::Cherokee qw(:utils);

use strict;
use utf8;
binmode(STDOUT, ":utf8");  # works fine w/o this on linux


print "<html>\n<body>\n";

$_ = "ᎠᎦᎭᎳᎹᎾᏆᏌᏓᏜᏣᏩᏯ";
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

s/(.)/setForm($1, 2)/eg;
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

s/(.)/setForm($1, 3)/eg;
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

s/(.)/setForm($1, 4)/eg;
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

s/(.)/setForm($1, 5)/eg;
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

s/(.)/setForm($1, 6)/eg;
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

s/(.)/setForm($1, 1)/eg;
print "$_<br>\n";
s/(.)/print getForm($1)/eg;
print "<br>\n";

print "</body>\n</html>\n";


__END__

=head1 NAME

utils.pl - Demonstrations of the Exported ":utils" Functions.

=head1 SYNOPSIS

./utils.pl

=head1 DESCRIPTION

Simple demonstrations of the functions exported under the ":utils"
pragma of the L<Regexp::Cherokee> package.  Check the L<Regexp::Cherokee>
package for documentation.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
