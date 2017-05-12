package Test::CheckChanges;
use strict;
use warnings;

use Cwd;
use Carp;
use File::Spec;
use File::Basename;
use File::Glob "bsd_glob";
use Test::Builder;

our $test      = Test::Builder->new();

=head1 NAME

Test::CheckChanges - Check that the Changes file matches the distribution.

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

 use Test::CheckChanges;
 ok_changes();

You can make the test optional with 

 use Test::More;
 eval { require Test::CheckChanges };

 if ($@) {
     plan skip_all => 'Test::CheckChanges required for testing the Changes file';
 }
 ok_changes();

=head1 DESCRIPTION

This module checks that you I<Changes> file has an entry for the current version 
of the B<Module> being tested.

The version information for the distribution being tested is taken out
of the Build data, or if that is not found, out of the Makefile.

It then attempts to open, in order, a file with the name I<Changes> or I<CHANGES>.

The I<Changes> file is then parsed for version numbers.  If one and only one of the
version numbers matches the test passes.  Otherwise the test fails.

A message with the current version is printed if the test passes, otherwise
dialog messages are printed to help explain the failure.

The I<examples> directory contains examples of the different formats of
I<Changes> files that are recognized.

=cut

our $order = '';
our @change_files = qw (Changes CHANGES);
our $changes_regex = qr/(Changes|CHANGES)$/;
our $glob = "C[Hh][Aa][Nn][Gg][Ee][Ss]";

sub import {
    my ($self, %plan) = @_;
    my $caller = caller;

    if (defined $plan{order}) {
       $order = $plan{order};
       delete $plan{order};
    }

    for my $func ( qw( ok_changes ) ) {
        no strict 'refs';	## no critic
        *{$caller."::".$func} = \&$func;
    }

    $test->exported_to($caller);
    $test->plan(%plan);
    return;
}

=head1 FUNCTIONS

All functions listed below are exported to the calling namespace.

=head2 ok_changes( )

=over

The ok_changes method takes no arguments and returns no value.

=back

=cut
 
our @not_found;

sub ok_changes
{
    my %p;
    %p = @_ if @_ % 2 == 0;
    my $version;
    my $msg = 'Unknown Error';
    my $_base = delete $p{base} || '';

    die "ok_changes takes no arguments" if keys %p || @_ % 2 == 1;

    my $base = Cwd::realpath(File::Spec->catdir(dirname($0), '..', $_base));

    my $home     = $base;
    my @diag = ();

    my $makefile = File::Spec->catdir($base, 'Makefile');
    my $build = File::Spec->catdir($home, '_build', 'build_params');

    my $extra_text;

    if ($build && -r $build) {
        require Module::Build::Version;
        open(my $in, '<', $build);
        my $data = join '', <$in>;
        close($in);
        my $temp = eval $data;		## no critic
        $version = $temp->[2]{dist_version};
        $extra_text = "Build";
    } elsif ($makefile && -r $makefile) {
        open(my $in, '<', $makefile) or die "Could not open $makefile";
        while (<$in>) {
            chomp;
            if (/^VERSION\s*=\s*(.*)\s*/) {
                $version = $1;
                $extra_text = "Makefile";
                last;
            }
        }
        close($in) or die "Could not close $makefile";
    }
    if ($version) {
        $msg = "CheckChages $version " . $extra_text;
    } else {
        push(@diag, "No way to determine version");
        $msg = "No Build or Makefile found";
    }

    my $ok = 0;

    my $mixed = 0;
    my $found = 0;
    my $parsed = '';
    @not_found = ();

    # glob for the changes file and then filter if needed
    # this is sorted here so the filesystem is not in control of 
    #  the order of the files.
    
    my $glob_path = File::Spec->catdir($home, $glob);
    my @change_list = sort { $b cmp $a } grep({ m|$changes_regex|} bsd_glob($glob_path));

    my $change_file = $change_list[0];

    if (@change_list > 1) {
        for (@change_list) {
            s|^$home/||;
        }
        push(@diag, qq/Multiple Changes files found (/ .
        join(', ', map({'"' . $_ . '"'} @change_list)) .
        qq/) using "$change_list[0]"./);
    }

    if ($change_file and $version) {
        open(my $in, '<', $change_file) or die "Could not open ($change_file) File";
        my $type = 0;
        while (<$in>) {
            chomp;
            if (/^(\d|v\d)/) {
# Common
                my ($cvers, $date) = split(/\s+/, $_, 2);
                    $mixed++ if $type and $type != 1;
                    $type = 1;
#                    if ($date =~ /- version ([\d.]+)$/) {
#                        $cvers = $1;
#                    }
                    if ($version eq $cvers) {
                        $found = $_;
                        last;
                    } else {
                        push(@not_found, "$cvers");
                    }
            } elsif (/^\s+version: ([\d.]+)$/) {
# YAML
                $mixed++ if $type and $type != 2;
                $type = 2;
                if ($version eq $1) {
                    $found = $_;
                    last;
                } else {
                    push(@not_found, "$1");
                }
            } elsif (/^\* (v?[\d._]+)$/) {
# Apocal
                $mixed++ if $type and $type != 3;
                $type = 3;
                if ($version eq $1) {
                    $found = $_;
                    last;
                } else {
                    push(@not_found, "$1");
                }
            } elsif (/^Version (v?[\d._]+)($|[:,[:space:]])/) {
# Plain "Version N"
                $mixed++ if $type and $type != 4;
                $type = 4;
                if ($version eq $1) {
                    $found = $_;
                    last;
                } else {
                    push(@not_found, "$1");
                }
            }
        }
        close($in) or die "Could not close ($change_file) file";
        if ($found) {
            $ok = 1;
        } else {
            $ok = 0;
            $msg .= " Not Found.";
            if (@not_found) {
                push(@diag, qq(expecting version $version, found versions: ). join(', ', @not_found));
            } else {
                push(@diag, qq(expecting version $version, But no versions where found in the Changes file.));
            }
        }
    } 
    if (!$change_file) {
        push(@diag, q(No 'Changes' file found));
    }

    $test->ok($ok, $msg);
    for my $diag (@diag) {
        $test->diag($diag);
    }
    return;
}

END {
    if (!defined $test->has_plan()) {
	$test->done_testing(1);
    }
}

1;

=head1 CHANGES FILE FORMAT

Currently this package parses 4 different types of C<Changes> files.
The first is the common, free style, C<Changes> file where the version
is first item on an unindented line:

 0.01  Fri May  2 15:56:25 EDT 2008
       - more info  

The second type of file parsed is the L<Module::Changes::YAML> format changes file.

The third type of file parsed has the version number proceeded by an * (asterisk).

 Revision history for Perl extension Foo::Bar

 * 1.00

 Is this a bug or a feature

The fourth type of file parsed starts the line with the word Version
followed by the version number.

 Version 6.00  17.02.2008
  + Oops. Fixed version number. '5.10' is less than '5.9'. I thought
    CPAN would handle this but apparently not..

There are examples of these Changes file in the I<examples> directory.

Create an RT if you need a different format file supported.  If it is not horrid, I will add it.

The Debian style C<Changes> file will likely be the first new format added.

=head1 BUGS

Please open an RT if you find a bug.

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Test-CheckChanges>

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2008-2010 G. Allen Morris III, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
