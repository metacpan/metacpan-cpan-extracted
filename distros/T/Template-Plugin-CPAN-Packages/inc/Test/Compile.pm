#line 1
package Test::Compile;

use warnings;
use strict;
use Test::Builder;
use File::Spec;
use UNIVERSAL::require;


our $VERSION = '0.08';


my $Test = Test::Builder->new;


sub import {
    my $self = shift;
    my $caller = caller;

   for my $func (qw(
       pm_file_ok pl_file_ok all_pm_files all_pl_files all_pm_files_ok
       all_pl_files_ok
       )) {

        no strict 'refs';
        *{$caller."::".$func} = \&$func;
    }

    $Test->exported_to($caller);
    $Test->plan(@_);
}


sub pm_file_ok {
    my $file = shift;
    my $name = @_ ? shift : "Compile test for $file";

    if (!-f $file) {
        $Test->ok(0, $name);
        $Test->diag("$file does not exist");
        return;
    }

    my $module = $file;
    $module =~ s!^(blib/)?lib/!!;
    $module =~ s!/!::!g;
    $module =~ s/\.pm$//;

    my $ok = 1;
    $module->use;
    $ok = 0 if $@;

    my $diag = '';
    unless ($ok) {
        $diag = "couldn't use $module ($file): $@";
    }

    $Test->ok($ok, $name);
    $Test->diag($diag) unless $ok;
    $ok;
}


sub pl_file_ok {
    my $file = shift;
    my $name = @_ ? shift : "Compile test for $file";

    # don't "use Devel::CheckOS" because Test::Compile is included by
    # Module::Install::StandardTests, and we don't want to have to ship
    # Devel::CheckOS with M::I::T as well.

    if (Devel::CheckOS->require) {

        # Exclude VMS because $^X doesn't work. In general perl is a symlink to
        # perlx.y.z but VMS stores symlinks differently...

        unless (Devel::CheckOS::os_is('OSFeatures::POSIXShellRedirection') and
                Devel::CheckOS::os_isnt('VMS')) {

            $Test->skip('Test not compatible with your OS');
            return;
        }
    }

    unless (-f $file) {
        $Test->ok(0, $name);
        $Test->diag("$file does not exist");
        return;
    }

    my $out = `$^X -cw $file 2>&1`;

    if ($?) {
        $Test->ok(0, 'Script does not compile');
        $Test->diag($out);
        return;
    } else {
        $Test->ok(1);
        return 1;
    }
}


sub all_pm_files_ok {
    my @files = @_ ? @_ : all_pm_files();

    $Test->plan(tests => scalar @files);

    my $ok = 1;
    for (@files) {
        pm_file_ok($_) or undef $ok;
    }
    $ok;
}


sub all_pl_files_ok {
    my @files = @_ ? @_ : all_pl_files();

    $Test->plan(tests => scalar @files);

    my $ok = 1;
    for (@files) {
        pl_file_ok($_) or undef $ok;
    }
    $ok;
}


sub all_pm_files {
    my @queue = @_ ? @_ : _pm_starting_points();
    my @pm;

    while (@queue) {
        my $file = shift @queue;
        if (-d $file) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            for my $newfile (@newfiles) {
                my $filename = File::Spec->catfile($file, $newfile);
                if (-f $filename) {
                    push @queue, $filename;
                } else {
                    push @queue, File::Spec->catdir($file, $newfile);
                }
            }
        }
        if (-f $file) {
            push @pm, $file if $file =~ /\.pm$/;
        }
    }
    @pm;
}


sub all_pl_files {
    my @queue = @_ ? @_ : _pl_starting_points();
    my @pl;

    while (@queue) {
        my $file = shift @queue;
        if (-d $file) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            for my $newfile (@newfiles) {
                my $filename = File::Spec->catfile($file, $newfile);
                if (-f $filename) {
                    push @queue, $filename;
                } else {
                    push @queue, File::Spec->catdir($file, $newfile);
                }
            }
        }
        if (-f $file) {
            # Only accept files with no extension or extension .pl
            push @pl, $file if $file =~ /(?:^[^.]+$|\.pl$)/;
        }
    }
    @pl;
}


sub _pm_starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}


sub _pl_starting_points {
    return 'script' if -e 'script';
    return 'bin' if -e 'bin';
}


1;


__END__

{% USE p = PodGenerated %}

#line 371

