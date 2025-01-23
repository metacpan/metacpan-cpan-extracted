#!/usr/bin/perl -w

use Regexp::Ethiopic::Amharic qw(:utils :forms overload);

use strict;
use utf8;
binmode(STDOUT, ":utf8");  # works fine w/o this on linux

main:
{
$_ = "ሀለሐመሠረሰ";

print "Staring with $_...\n\n";

print "1) Set all [=ሀ=] to the ራብዕ form:\n";
# print "   ", qw(s/([=ሀ=])/setForm($1,$ራብዕ)/eg;), "\n";
print "   s/([=ሀ=])/setForm(\$1,\$ራብዕ)/eg;\n";
s/([=ሀ=])/setForm($1,$ራብዕ)/eg;
print "   => $_\n\n";


print "2) Set all [=ሰ=] to the ሳብዕ form:\n";
# print "   ", qw(s/([=ሰ=])/setForm($1,$ሳብዕ)/eg;), "\n";
print "   s/([=ሰ=])/setForm(\$1,\$ሳብዕ)/eg;)\n";
s/([=ሰ=])/setForm($1,$ሳብዕ)/eg;
print "   => $_\n\n";


print "3) Set all ግዕዝ forms to the ኃምስ form:\n";
# print "   ", qw(s/([:ግዕዝ:])/setForm($1,$ኃምስ)/eg;), "\n";
print "   s/([:ግዕዝ:])/setForm(\$1,\$ኃምስ)/eg;\n";
s/([:ግዕዝ:])/setForm($1,$ኃምስ)/eg;
print "   => $_\n\n";

print "   Note: This last substitution was equivalent to:\n";
# print "        ", qw(s/([#1#])/setForm($1,$ኃምስ)/eg;), "\n\n";
print "        s/([#1#])/setForm(\$1,\$ኃምስ)/eg;\n\n";


print "4) Substitute a [#ጸ#] for a [#ሰ#] in the form found for the [#ሰ#]:\n";
# print "   ", qw(s/([#ሰ#])/subForm('ጸ',$1)/eg;), "\n";
print "   s/([#ሰ#])/subForm('ጸ',\$1)/eg;\n";
s/([#ሰ#])/subForm('ጸ',$1)/eg;
print "   => $_\n\n";


print "5) Report all forms:\n";
# print "   ", qw(s/(.)/print "   $1 is of form ", getForm($1),"\n"; $1/eg), "\n";
print "   s/(.)/print \"   \$1 is of form \", getForm(\$1),\"\\n\"; \$1/eg\n";
s/(.)/print "   $1 is of form ", getForm($1),"\n"; $1/eg;
print "\n";


print "6) Back to where we started (except for the ጸ of course):\n";
# print "   ", qw(s/(.)/setForm($1,$ግዕዝ)/eg;), "\n";
print "   s/(.)/setForm(\$1,\$ግዕዝ)/eg;\n";
s/(.)/setForm($1,$ግዕዝ)/eg;
print "   => $_\n\n";


print "7) Format አበገደ as አቡጊዳ:\n";

print "   print formatForms ( \"%1%2%3%4\", \"አበገደ\" );\n";
print "   => ", formatForms ( "%1%2%3%4", "አበገደ" ), "\n";


}


__END__

=head1 NAME

utils.pl - 7 Demonstrations of the Exported ":utils" Functions.

=head1 SYNOPSIS

./utils.pl

=head1 DESCRIPTION

Simple demonstrations of the functions exported under the ":utils"
pragma of the L<Regexp::Ethiopic> and L<Regexp::Ethiopic::Amharic>
packages.  Some examples are a little contrived just to keep the
example simple.  Check the L<Regexp::Ethiopic> package for documentation.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
