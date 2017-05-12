#!/usr/bin/perl
# this is a utility script I use to add a new class,
# run it from the top directory (where Ogre.pm is)

use strict;
use warnings;

use File::Spec;
use File::Slurp;
use List::MoreUtils qw(none first_index);

my $XSDIR = 'xs';
my $PMDIR = 'Ogre';

main();
exit();

sub main {
    my $class = get_class();

    write_xs_file($class);
    write_pm_file($class);
    update_manifest($class);
    update_ogrepm($class);
    update_typemap($class);
}

sub get_class {
    die "usage: $0 classname < [text]\n" unless @ARGV;
    return shift(@ARGV);
}

sub write_xs_file {
    my ($class) = @_;

    my $file = File::Spec->catfile($XSDIR, $class . '.xs');
    if (-f $file) {
        print "XS file '$file' already exists\n";
    }
    else {
        write_file($file, "MODULE = Ogre     PACKAGE = Ogre::$class\n\n");
        print "wrote XS file '$file'\n";
    }
}

sub write_pm_file {
    my ($class) = @_;

    # (very similar to write_xs_file)
    my $file = File::Spec->catfile($PMDIR, $class . '.pm');
    if (-f $file) {
        print "PM file '$file' already exists\n";
    }
    else {
        write_file($file, "package Ogre::$class;\n\nuse strict;\nuse warnings;\n\n\n1;\n\n__END__\n");
        print "wrote PM file '$file'\n";
    }
}

sub update_manifest {
    my ($class) = @_;

    my $file = 'MANIFEST';
    my @lines = read_file($file);

    # add PM file
    my $pmfile = "$PMDIR/$class.pm";
    if (none { /^$pmfile$/ } @lines) {
        push @lines, "$pmfile\n";
    }

    # add XS file
    my $xsfile = "$XSDIR/$class.xs";
    if (none { /^$xsfile$/ } @lines) {
        push @lines, "$xsfile\n";
    }

    write_file($file, sort(@lines));
    print "MANIFEST updated\n";
}

sub update_ogrepm {
    my ($class) = @_;

    my $file = 'Ogre.pm';
    my @lines = read_file($file);

    # if it's not there already, add it into the "use" lines
    if (none { /^use Ogre::$class;/ } @lines) {
        my $begin_index = first_index { /^## BEGIN USES/ } @lines;
        my $end_index   = first_index { /^## END USES/   } @lines;

        my $offset = $begin_index + 1;
        my $length = $end_index - $offset;

        my @replaced_lines = @lines[$offset .. $end_index - 1];
        push @replaced_lines, "use Ogre::$class;\n";

        splice @lines, $offset, $length, sort(@replaced_lines);

        write_file($file, @lines);
    }

    print "$file updated\n";
}

sub update_typemap {
    my ($class) = @_;

    my $file = 'typemap';
    my @lines = read_file($file);


    # if it's not there already, add it
    # (very similar to update_ogrepm)
    if (none { /^$class \*\tO_/ } @lines) {
        my $begin_index = first_index { /^## BEGIN NORMAL TYPEMAPS/ } @lines;
        my $end_index   = first_index { /^## END NORMAL TYPEMAPS/   } @lines;

        my $offset = $begin_index + 1;
        my $length = $end_index - $offset;

        my @replaced_lines = @lines[$offset .. $end_index - 1];
        push @replaced_lines, "$class *\t\UO_$class\n";
        push @replaced_lines, "const $class *\t\UO_$class\n";

        splice @lines, $offset, $length, sort(@replaced_lines);

        write_file($file, @lines);
    }

    print "$file TYPEMAP updated;  update INPUT and OUTPUT sections manually!\n";
}
