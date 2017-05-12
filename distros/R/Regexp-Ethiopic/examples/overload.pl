#!/usr/bin/perl -w

use Regexp::Ethiopic::Amharic 'overload';

use strict;
use utf8;
binmode(STDOUT, ":utf8");  # works fine w/o this on linux

main:
{
my $ፈተና = "ዓለምፀሐይ";

print "Basic Property Tests...\n";
print "  ፈተና  ፩፦ ዓለምፀሐይ matches /([=አ=])ለም[=ጸ=][=ሃ=]ይ/\n" if ( $ፈተና =~ /([=አ=])ለም[=ጸ=][=ሃ=]ይ/ );
print "  ፈተና  ፪፦ ዓለምፀሐይ contains /[#ለ#]ም/\n"              if ( $ፈተና =~ /[#ለ#]ም/ );
print "  ፈተና  ፫፦ ዓለምፀሐይ contains /[#4#]ለ/\n"              if ( $ፈተና =~ /[#4#]ለ/ );

print "Form Range Tests...\n";
print "  ፈተና  ፬፦ ዓለምፀሐይ contains /[#4-6#]ለ/\n"            if ( $ፈተና =~ /[#4-6#]ለ/ );
print "  ፈተና  ፭፦ ዓለምፀሐይ contains /[#4,6#]ለ/\n"            if ( $ፈተና =~ /[#4,6#]ለ/ );
print "  ፈተና  ፮፦ ዓለምፀሐይ contains /[#ለ-መ#]/\n"             if ( $ፈተና =~ /[#ለ-መ#]/ );
print "  ፈተና  ፯፦ ዓለምፀሐይ contains /[#ለ-መ#]/\n"             if ( $ፈተና =~ /[#ለመ#]/ );

print "Form Range Operator Tests...\n";
print "  ፈተና  ፰፦ ዓለምፀሐይ contains መ{#4-7#}\n"               if ( $ፈተና =~ /መ{#4-7#}/ );
print "  ፈተና  ፱፦ ዓለምፀሐይ contains ፀ{#1,3-5,7#}\n"           if ( $ፈተና =~ /ፀ{#1,3-5,7#}/ );

print "  ፈተና  ፲፦ ዓለምፀሐይ does not contain [ጸ]{#3#}\n"       if ( $ፈተና !~ /[ጸ]{#3#}/ );
print "  ፈተና ፲፩፦ ዓለምፀሐይ does not contain [ጸ]{#11#}\n"      if ( $ፈተና !~ /[ጸ]{#11#}/ );
print "  ፈተና ፲፪፦ ዓለምፀሐይ does not contain [ጸ]{#3-5#}\n"     if ( $ፈተና !~ /[ጸ]{#3-5#}/ );
print "  ፈተና ፲፫፦ ዓለምፀሐይ does not contain [ጸ]{#3,5,7#}\n"   if ( $ፈተና !~ /[ጸ]{#3-5,7#}/ );
print "  ፈተና ፲፬፦ ዓለምፀሐይ does not contain [ጸ]{#3,5#}\n"     if ( $ፈተና !~ /[ጸ]{#3,5#}/ );

print "  ፈተና ፲፭፦ ዓለምፀሐይ does not contain [ሐጸ]{#4#}\n"      if ( $ፈተና !~ /[ሐጸ]{#4#}/ );
print "  ፈተና ፲፮፦ ዓለምፀሐይ does not contain [ሐጸ]{#3,5#}\n"    if ( $ፈተና !~ /[ሐጸ]{#3,5#}/ );

print "  ፈተና ፲፯፦ ዓለምፀሐይ contains [ለ-መ]{#6#}\n"             if ( $ፈተና =~ /[ለ-መ]{#6#}/ );
print "  ፈተና ፲፰፦ ዓለምፀሐይ does not contain /[ለ-መ]{#3,5#}/\n" if ( $ፈተና !~ /[ለ-መ]{#3,5#}/ );
print "  ፈተና ፲፱፦ ዓለምፀሐይ contains [ለ-መ]{#3,5-7#}\n"         if ( $ፈተና =~ /[ለ-መ]{#3,5-7#}/ );

print "  ፈተና  ፳፦ ዓለምፀሐይ does not contain /[ጸለ-መ]{#4#}/\n"  if ( $ፈተና !~ /[ጸለ-መ]{#4#}/ );
print "  ፈተና ፳፩፦ ዓለምፀሐይ matches /[ጸለ-መ]{#3,5-7#}/\n"       if ( $ፈተና =~ /[ጸለ-መ]{#3,5-7#}/ );

#
# negation:
#
print "Negation Tests...\n";
print "  ፈተና ፳፪፦ ዓለምፀሐይ matches [ሐጸ]{^#4#}\n"              if ( $ፈተና =~ /[ሐጸ]{^#4#}/ );
print "  ፈተና ፳፫፦ ዓለምፀሐይ matches [^ሐጸ]{#4#}\n"              if ( $ፈተና =~ /[^ሐጸ]{#4#}/ );
print "  ፈተና ፳፬፦ ዓለምፀሐይ matches [^ሐጸ]{^#4#}\n"             if ( $ፈተና =~ /[^ሐጸ]{^#4#}/ );  # double negative remains negative (as per amharic grammar)

#
# Ethiopic Class Tests
#
print "Ethiopic Class Tests...\n";
print "  ፈተና ፳፭፦ ኩ is of [#ከ#]\n"    if ( "ኩ" =~ /[#ከ#]/ );
print "  ፈተና ፳፮፦ ኩ is of [#2#]\n"    if ( "ኩ" =~ /[#2#]/ );
print "  ፈተና ፳፯፦ ኩ is of [:ካዕብ:]\n"  if ( "ኩ" =~ /[:ካዕብ:]/ );
print "  ፈተና ፳፰፦ ኩ is of [:kaib:]\n" if ( "ኩ" =~ /[:kaib:]/ );


print "Amharic Family Equivalence Test...\n";
print "  ፈተና ፳፱፦ ዓለምፀሐይ contains [=#ጸ#=]\n" if ( $ፈተና =~ /[=#ጸ#=]/ );
print "  ፈተና ፴፦ ዓለምፀሐይ contains [=#ሀ#=]\n"  if ( $ፈተና =~ /[=#ሀ#=]/ );

}


__END__

=head1 NAME

overload.pl - Test Ethiopic RE Overloading.

=head1 SYNOPSIS

./overload.pl

=head1 DESCRIPTION

A demonstrator script to illustrate regular expressions for Amharic.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=cut
