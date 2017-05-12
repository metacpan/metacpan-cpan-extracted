#!/usr/bin/perl
# Sloppy script to generate XSUBs for nsI* interfaces.
#
# Given the name of a Mozilla DOM interface header file,
# this generates XSUBs for a Mozilla::DOM package. For example,
#
#   for f in `find /usr/include/mozilla -name 'nsIDOMHTML*Element.h'`;
#   do echo $f; ./gendomxsubs.pl $f; done
#
# will create a file in a 'genxsubs' directory for each header file,
# each containing its own MODULE/PACKAGE line.
#
# Note: if the header file name is inconsistent with the interface
# (e.g. nsIDOMHTMLTableSectionElement is nsIDOMHTMLTableSectionElem.h)
# you'll have to copy the file or symlink to it.

use strict;
use warnings;

# This only works on interface headers
unless (@ARGV == 1 && $ARGV[0] =~ /nsI.+\.h$/) {
    die "Usage: $0 /path/nsISomething.h\n";
}

# This gets output for pasting convenience
my @wrappercode = ();

my $headerfile = $ARGV[0];
(my $iface = $headerfile) =~ s{.*/([^.]+)\.h}{$1};

my $pkgbase = 'Mozilla::DOM';
(my $pkgname = $iface) =~ s/^nsI(DOM)?//;
my $pkg = "$pkgbase\::$pkgname";
my $outfile = "genxsubs/$iface.xs";

push @wrappercode, "cat $outfile >> xs/DOM.xs\n";
push @wrappercode, qq{#include "$iface.h" (mozilladom2perl.h)\n};
push @wrappercode, "MOZDOM_DECL_DOM_TYPEMAPPERS($pkgname) (mozilladom2perl.h)\n";
push @wrappercode, "MOZDOM_DEF_DOM_TYPEMAPPERS($pkgname) (xs/DOM.xs)\n";

(my $obj = lc($iface)) =~ s/^nsi(dom)?//i;
unless (defined $1) {
    $wrappercode[-1] =~ s/_DOM_/_I_/;
    $wrappercode[-2] =~ s/_DOM_/_I_/;
}
push @wrappercode, "$iface *\t\tT_MOZDOM_GENERIC_WRAPPER  (mozilladom.typemap)\n";
push @wrappercode, "$iface\t\t$pkg  (doctypes)\n";
push @wrappercode, "add an entry to QueryInterface\n";
push @wrappercode, "do ISA in DOM.pm\n";
push @wrappercode, "add POD file\n";
push @wrappercode, "update ChangeLog, MANIFEST\n";

print $_ for @wrappercode;


my $prefix = 'moz_dom_';
my $parentclass = '';
my $inapi = 0;

my $incomment = 0;
my $classcomment = '';
my $gotclasscomment = 0;
my $raisecomment = '';

my @methods = ();
my $getiid = '';

my @enums = ();


# Gather information from header file
while (<>) {
    ## Comments

    if ($incomment) {
        # Trying to look for the class's main comment.
        # (Unfortunately this doesn't always have a '@status' in it,
        # but I didn't know what else to do.)
        if (/\@status/) {
            $gotclasscomment = 1;
            $classcomment .= $_;
        } elsif (m{\*/}) {
            $incomment = 0;
        } else {
            $classcomment .= $_;
        }
    } elsif (m{/\*}) {
        if (m{\*/}) {
            # Make a note if the method raises an exception
            # (I grepped all headers for 'raises' comments,
            # and all of them were contained on a single line)
            if (/(raises\s*\([^)]\))/) {
                $raisecomment = "/* $1 */";
            }
        } else {
            # Start of a comment
            $incomment = 1;
            # Erase previous comment if it wasn't a class comment
            $classcomment = '' unless $gotclasscomment;
        }
    }

    ## Class API

    if (/^\s*class .*$iface\s*:\s*public \s*([^\s]+)/) {
        # Beginning of class declaration
        if (defined $1) {
            $parentclass = $1;
            $parentclass =~ s/^nsI(DOM)?//;
        } else {
            die "no parent class found\n";
        }
        $inapi = 1;
    } elsif ($inapi) {
        next unless /\S/;

        if (/^\s*}\s*;/) {
            # End of class declaration
            $inapi = 0;
            last;
        } elsif (/(NS_DEFINE_STATIC_IID_[^)]+\))/) {
            # The GetIID() class method (only put in a comment)
            $getiid = $1;
        } elsif (/NS_IMETHOD\s*([^\s(]+)\s*\(\s*([^)]+)\s*\)/) {
            # Parse a method declaration

            my $signature = $2;

            my %method = (
                orig => "$1\($2)",
                name => $1,
                inputs => [],
            );

            # print $method{orig}, $/;

            if ($raisecomment) {
                $method{raises} = $raisecomment;
                $raisecomment = '';
            }

            foreach my $arg (split(/\s*,\s*/, $signature)) {
                if ($arg eq 'void') {
                    # nothing to do
                } elsif ($arg =~ /^(.+)\s*\b(\w+)$/) {
                    my $type = $1;
                    my $name = $2;

                    die "unknown type '$type' in method signature\n"
                      unless $type =~ /(nsAC?String|nsI|PR[BIU].*|DOMTimeStamp|const char \*)/;

#                    $name =~ s/_//g;
#                    $name =~ s/^[a-z]([A-Z])/$1/;
#                    $name = lc $name;

                    if ($type =~ s/\*\s*\*$/*/
                          or $type =~ s/(PR(?:Bool|Uint16|Uint32|Int16|Int32))\s*\*/$1/)
                    {
                        # It's an output argument like 'nsIDOMAttr **'
                        # or 'PRBool *'
                        $method{output} = { type => $type, name => $name };
                    } elsif ($type !~ /const/ and $type =~ /nsA(C?String)/) {
                        # It's an output argument like 'nsAString &'
                        $type = "nsEmbed$1";
                        $method{output} = { type => $type, name => $name };
                    } else {
                        # It's an input argument
                        if ($type =~ /nsA(C?String)/) {
                            $type = "nsEmbed$1";
                        }
                        push @{ $method{inputs} }, { type => $type, name => $name };
                    }
                } else {
                    die "unknown argument '$arg' in method signature\n";
                }
            }

            push @methods, \%method;
        } elsif (/enum\s*{\s*(\w+)\s*=\s*(\d+)U?/) {
            push @enums, { name => $1, value => $2 };
        }
    }
}

$classcomment = '' unless $gotclasscomment;


# Write out the XS file
mkdir 'genxsubs';

open(OUT, ">$outfile") || die "can't open $outfile: $!";

print OUT <<EOH;
# -----------------------------------------------------------------------------

MODULE = $pkgbase	PACKAGE = $pkg	PREFIX = $prefix

# $headerfile

EOH

print OUT <<EOG;
## $getiid
static nsIID
$iface\::GetIID()
    CODE:
	const nsIID &id = $iface\::GetIID();
	RETVAL = (nsIID) id;
    OUTPUT:
	RETVAL

EOG

my @pod = ();
foreach my $method (@methods) {
    # Ugh, this is horrible

    my $pret = '';
    if (exists $method->{output}) {
        if ($method->{output}{type} =~ /bool/i) {
            $pret .= '$bool = ';
        } else {
            my $name = $method->{output}{name};
            $name =~ s/_//g;
            $name =~ s/^[a-z]([A-Z])/$1/;
            $name = lc $name;

            $pret .= "\$$name = ";
        }
    }
    my $psig = join(', ', map {
        my $name = $_->{name};
        $name =~ s/_//g;
        $name =~ s/^[a-z]([A-Z])/$1/;
        $name = lc $name;
        "\$$name"
    } @{ $method->{inputs} });

    my $xsret = (exists $method->{output})
      ? $method->{output}{type}
      : 'void';
    my $xssig = join(', ', ($obj, map {$_->{name}} @{ $method->{inputs} }));;
    my $xssigdecl = (@{ $method->{inputs} })
      ? (join(";\n", map {"\t$_->{type} $_->{name}"} @{ $method->{inputs} })
          . ";\n")
      : '';
    my $xspre = (exists $method->{output})
      ? "    PREINIT:\n\t$method->{output}{type} $method->{output}{name};\n"
      : '';
    my $xsout = (exists $method->{output})
      ? "\tRETVAL = $method->{output}{name};\n    OUTPUT:\n\tRETVAL\n"
      : '';

    my $ccode = "    CODE:\n";
    $ccode .= "\t/* $method->{raises} */\n" if exists $method->{raises};
    $ccode .= "\t$obj\->$method->{name}\(";
    # return value is assumed last
    $ccode .= join(', ', map {$_->{name}} @{ $method->{inputs} });
    if (exists $method->{output}) {
        $ccode .= ', ' if @{ $method->{inputs} };
        $ccode .= '&' unless $method->{output}{type} =~ /nsEmbedC?String/;
        $ccode .= $method->{output}{name};
    }
    $ccode .= ');';

    my $pod = "=head2 $pret\$$obj\->B<$method->{name}>\($psig)\n\n";
    if (@{ $method->{inputs} }) {
        $pod .= "Input:\n\n=over\n\n";
        foreach my $input (@{ $method->{inputs} }) {
            my $name = '$' . $input->{name};
            my $type = $input->{type};
            if ($type =~ s/^nsI(?:DOM)//) {
                $type = 'Mozilla::DOM::' . $type;
            }
            $type =~ s/\s*\*\s*$//;
            $type = 'int' if $type =~ /PR.*int/i;
            $type = 'string' if $type =~ /string/i;
            $type = 'bool' if $type =~ /bool/i;
            $pod .= "=item $name ($type)\n\n";
        }
        $pod .= "=back\n\n";
    }
    if (exists $method->{output}) {
        $pod .= "Output:\n\n=over\n\n";

        my $name = $method->{output}{name};
        my $type = $method->{output}{type};

        $name =~ s/_//g;
        $name =~ s/^[a-z]([A-Z])/$1/;
        $name = lc $name;
        $name = 'bool' if $type =~ /bool/i;
        $name = '$' . $name;

        if ($type =~ s/^nsI(?:DOM)//) {
            $type = 'Mozilla::DOM::' . $type;
        }
        $type =~ s/\s*\*\s*$//;
        $type = 'int' if $type =~ /PR.*int/i;
        $type = 'string' if $type =~ /string/i;
        $type = 'bool' if $type =~ /bool/i;
        $pod .= "=item $name ($type)\n\n";

        $pod .= "=back\n\n";
    }
    push @pod, $pod;

    print OUT <<EOM;
## $method->{orig}
$xsret
${prefix}$method->{name} \($xssig)
	$iface *$obj;
$xssigdecl$xspre$ccode
$xsout
EOM
}

close(OUT);


# output POD to separate file

my $podfile = "genxsubs/$pkgname.pod";
open(POUT, ">$podfile") || die "can't open $podfile: $!";

print POUT <<HEAD;
=head1 NAME

$pkg

=for object $pkg

$pkg is a wrapper around an instance of Mozilla's
$iface interface. This class inherits from
L\<$parentclass|$pkgbase\::$parentclass>.

HEAD

print POUT "$classcomment\n\n" if $classcomment;

if (@enums) {
    print POUT "The following constants are available.\n\n",
      "=over 4\n\n";

    foreach my $enum (@enums) {
        print POUT "=item $enum->{name} => $enum->{value}\n\n";
    }

    print POUT "=back\n\n";
}

print POUT <<POD;
=head1 CLASS METHODS

=head2 \$iid = $pkg\->B\<GetIID>()

Pass this to QueryInterface.

=head1 METHODS

POD

foreach my $pod (@pod) {
    print POUT $pod;
}

print POUT <<FOOT;
=head1 SEE ALSO

L<Mozilla::DOM>

=head1 COPYRIGHT

Copyright (C) 2005, Scott Lanning

This software is licensed under the LGPL.  See L<Mozilla::DOM> for a full notice.

=cut

FOOT

close(POUT);
