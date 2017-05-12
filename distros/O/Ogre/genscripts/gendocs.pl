#!/usr/bin/perl
# Run this from the top directory (where Ogre.xs is).
# This is what I'm using to generate doc stubs
# in Ogre/*.pm from the XS files xs/*.xs .

use strict;
use warnings;

use File::Copy;
use File::Spec;

my $XSDIR = 'xs';
my $PMDIR = 'Ogre';

my $BEGINCLASS = 'CLASS LIST BEGIN';
my $ENDCLASS = 'CLASS LIST END';

main();
exit();

sub main {
    my $xss = File::Spec->catfile(File::Spec->curdir, $XSDIR, '*.xs');
    my @xsfiles = glob($xss);

    foreach my $xsfile (@xsfiles) {
        my ($sigs, $package) = read_signatures($xsfile);

        my $debug = 0;
        if ($debug) {
            print "package: $package\n\n";
            foreach my $sig (@$sigs) {
                print "method: $sig->{method}\n";
                print "params: $sig->{params}\n";
                print "types: ", join(', ', @{ $sig->{types} }), $/;
                print "return: $sig->{return}\n\n";
            }
        }
        else {
            my $pmfile = pmfile_from_xsfile($xsfile);
            update_pod($pmfile, $sigs, $package);
        }
    }

    update_class_list();
}

# This assumes a certain structure of the XS files...
# First of all, there is only one MODULE line per file,
# and it specifies the PACKAGE. After grabbing the MODULE line,
# the first non-comment line that begins with a word character
# will be a return value type. Now we're "in" a signature.
# The next line is the method with its parameter names in parentheses,
# followed by the type declarations of the parameters. The parameters
# stop at either a blank line or a line ending in a colon (CODE:, etc.).
# This function returns
# 1) an aref of "signature" hashrefs, whose keys are:
# - method: the name of a method
# - params: a string of what's between parens (params) after the method name
# - types: an aref of the following lines giving the param types
# - return: the return value's type
# 2) the package name, gotten from PACKAGE
sub read_signatures {
    my ($file) = @_;

    my @sigs = ();
    my $insig = 0;
    my $package = '';
    my $return = '';
    my $method = '';
    my $params = '';
    my @types = ();

    open(my $fh, $file) || die "Can't open C file '$file': $!";
    while (<$fh>) {
        chomp;

        # grab the package name
        if (/^MODULE\s*=\s*\S+\s*PACKAGE\s*=\s*(\S+)$/) {
            $package = $1;
        }

        # if we're not already reading a signature
        elsif (! $insig) {
            # sigs only start with a word character (\w)
            # (implying it's not a comment (#), blank line, whitespace)

            if (/^(\w.+)$/) {
                # that was the return value's type
                $return = $1;
                $insig = 1;
            }
        }

        # we've already started reading a signature
        else {
            # match the method(params) line,
            # leaving out any class name (like Vector3::)
            if (/^(?:\w+::)*([^:(\s]+)\s*\((\s*[^)]*\s*)\)\s*$/) {
                $method = $1;
                $params = $2;
            }

            # ...and then if we encounter either a blank line
            # or a trailing colon (CODE:, C_ARGS:, etc.),
            # we're done reading the sig
            elsif (/^\s*$/ || /:\s*$/) {
                push @sigs, {
                    method  => $method,
                    params  => $params,
                    types   => [splice @types],
                    return  => $return,
                };

                $method = '';
                $return = '';
                $params = '';

                $insig = 0;
            }

            # we have the method already, and we're not done,
            # so this line is specifying the type of an argument
            elsif ($method) {
                # remove leading/trailing/duplicate whitespace
                s/(^\s+|\s+$)//;
                s/\s+/ /g;
                push @types, $_;
            }
        }
    }
    close($fh);

    # if there was nothing after the last method,
    # we're still in a signature, so it didn't get pushed yet
    if ($insig) {
        push @sigs, {
            method  => $method,
            params  => $params,
            types   => [splice @types],
            return  => $return,
        };
    }

    return(\@sigs, $package);
}

sub update_pod {
    my ($pmfile, $sigs, $package) = @_;

    # create the file if it doesn't already exist
    unless (-f $pmfile) {
        open(my $fh, "> $pmfile") || die "Couldn't create .pm file '$pmfile': $!";
        # note: important to put two \n
        # so that output_docs has a chance to output the docs
        print $fh "package $package;\n\nuse strict;\nuse warnings;\n\n\n1;\n\n__END__\n\n";
        close($fh);
    }

    # we'll copy the original to *~, and overwrite the original
    my $origpmfile = $pmfile . '.bak~';
    unless (copy($pmfile, $origpmfile)) {
        print STDERR "Couldn't copy .pm file '$pmfile': $!\n";
        return;
    }

    my $end = 0;

    open(my $newfh, "> $pmfile") || die "Couldn't open new .pm file '$pmfile' for writing: $!";
    open(my $oldfh, $origpmfile) || die "Couldn't open original .pm file '$origpmfile': $!";
    while (<$oldfh>) {
        if (/^__END__/) {
            $end = 1;
            print $newfh $_;
        }

        # we've already reached the end, so output docs
        elsif ($end) {
            output_docs($newfh, $sigs, $package);
            last;
        }

        # we haven't reached the end yet, so pass the original line through
        else {
            print $newfh $_;
        }
    }
    close($oldfh);

    # we didn't find an __END__, so make one and print the docs
    unless ($end) {
        print $newfh "\n__END__\n";
        output_docs($newfh, $sigs, $package);
    }

    close($newfh);
}

# update Ogre.pm's class list
sub update_class_list {
    my $pmfile = File::Spec->catfile(File::Spec->curdir, 'Ogre.pm');
    my @pmfiles = grep { ! /CEGUI/ }     # top secret :)
      glob(File::Spec->catfile(File::Spec->curdir, $PMDIR, '*.pm'));

    # backup old file
    my $oldfile = $pmfile . '.bak~~';
    unless (copy($pmfile, $oldfile)) {
        print STDERR "Couldn't copy '$oldfile' '$pmfile': $!\n";
        return;
    }

    my $gensection = 0;

    open(my $newfh, "> $pmfile") || die "Can't open file '$pmfile': $!";
    open(my $oldfh, $oldfile)     || die "Can't open file '$oldfile': $!";
    while (<$oldfh>) {
        if (m{$BEGINCLASS}) {
            $gensection = 1;
            print $newfh $_;
        }

        elsif (m{$ENDCLASS}) {
            # where the work actually is done,
            # updating the lines between the begin and end strings

            print $newfh "\n=over\n\n";
            foreach my $file (@pmfiles) {
                my ($pkg) = $file =~ m{/([^/]+)\.pm$};
                print $newfh "=item L<Ogre::$pkg>\n\n";
            }
            print $newfh "=back\n\n";

            print $newfh $_;
            $gensection = 0;
        }

        elsif ($gensection) {
            next;
        }

        else {
            print $newfh $_;
        }
    }

    if ($gensection) {
        die "No end string found in file '$pmfile'\n";
    }

    close($oldfh);
    close($newfh);
}

sub output_docs {
    my ($fh, $sigs, $package) = @_;

    my $oldfh = select($fh);

    print "=head1 NAME\n\n";
    print "$package\n\n";
    print "=head1 SYNOPSIS\n\n";
    print "  use Ogre;\n  use $package;\n  # (for now see examples/README.txt)\n\n";

    (my $pkg = $package) =~ s/:/_1/g;
    my $ogreurl = "http://www.ogre3d.org/docs/api/html/class$pkg.html";
    print "=head1 DESCRIPTION\n\n";
    print "See the online API documentation at\n L<$ogreurl>\n\n";
    print "B<Note:> this Perl binding is currently I<experimental> and subject to API changes.\n\n";

    # xxx: should also output a class hierarchy
    # if this package inherits from anything

    my @class_methods = grep { is_static_method($_) } @$sigs;
    my @instance_methods = grep { ! is_static_method($_) } @$sigs;

    # xxx: really need to factor some of this out..

    print "=head1 CLASS METHODS\n\n" if @class_methods;
    foreach my $sig (@class_methods) {
        # xxx: this doesn't handle the "constant" xsubs.... (ALIASed)
        # I want to change constants soon anyway.

        if ($sig->{method} eq 'DESTROY') {
            print "=head2 ${package}->$sig->{method}()\n\n";
            print "This method is called automatically; don't call it yourself.\n\n";
        }
        elsif ($sig->{method} =~ /_xs$/) {
            print "=head2 \\\&$sig->{method}\n\n";
            print "This is an operator overload method; don't call it yourself.\n\n";
        }
        else {
            my @param_names = map { ($_ eq '...') ? $_ : ('$' . $_) }
              split(/\s*,\s*/, $sig->{params});
            my $params = join(', ', @param_names);
            print "=head2 ${package}->$sig->{method}($params)\n\n";

            if (@param_names) {
                print "I<Parameter types>\n\n=over\n\n";
                foreach my $i (0 .. $#param_names) {
                    my $name = $param_names[$i];
                    my $type = $sig->{types}[$i] || '';

                    if ($name eq '...') {
                        $type = 'this varies... (sorry, look in the .xs file)';
                    }
                    elsif ($type eq '') {
                        $type = '(no info available)';
                    }
                    else {
                        $type =~ s/ \w+$//;
                    }
                    $type =~ s/DegRad/Degree (or Radian)/;
                    print "=item $name : $type\n\n";
                }
                print "=back\n\n";
            }

            (my $return = $sig->{return}) =~ s/static //;
            print "I<Returns>\n\n=over\n\n=item $return\n\n=back\n\n";
        }
    }

    print "=head1 INSTANCE METHODS\n\n" if @instance_methods;
    foreach my $sig (@instance_methods) {
        my @param_names = map { $_ eq '...' ? $_ : '$' . $_ }
          split(/\s*,\s*/, $sig->{params});
        my $params = join(', ', @param_names);
        print "=head2 \$obj->$sig->{method}($params)\n\n";

        if (@param_names) {
            print "I<Parameter types>\n\n=over\n\n";
            foreach my $i (0 .. $#param_names) {
                my $name = $param_names[$i];
                my $type = $sig->{types}[$i] || '';

                if ($name eq '...') {
                    $type = 'this varies... (sorry, look in the .xs file)';
                }
                elsif ($type eq '') {
                    $type = '(no info available)';
                }
                else {
                    $type =~ s/ \w+$//;
                }
                $type =~ s/DegRad/Degree (or Radian)/;
                print "=item $name : $type\n\n";
            }
            print "=back\n\n";
        }

        (my $return = $sig->{return}) =~ s/static //;
        print "I<Returns>\n\n=over\n\n=item $return\n\n=back\n\n";
    }

    print "=head1 AUTHOR\n\nScott Lanning E<lt>slanning\@cpan.orgE<gt>\n\n";
    print "For licensing information, see README.txt .\n\n=cut\n";

    select($oldfh);
}

sub is_static_method {
    my ($sig) = @_;
    return $sig->{return} =~ /static/
           || $sig->{method} eq 'new'
           || $sig->{method} eq 'DESTROY'
           || $sig->{method} =~ /_xs$/
}

sub pmfile_from_xsfile {
    my ($xsfile) = @_;

    my $pmfile = $xsfile;
    $pmfile =~ s/^$XSDIR/$PMDIR/;
    $pmfile =~ s/xs$/pm/;

    return $pmfile;
}
