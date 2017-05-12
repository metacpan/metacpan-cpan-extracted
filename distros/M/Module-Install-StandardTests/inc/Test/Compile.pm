#line 1
package Test::Compile;

use warnings;
use strict;
use Test::Builder;
use File::Spec;
use UNIVERSAL::require;


our $VERSION = '0.04';


my $Test = Test::Builder->new;


sub import {
    my $self = shift;
    my $caller = caller;

   for my $func ( qw( pm_file_ok all_pm_files all_pm_files_ok ) ) {
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


sub all_pm_files_ok {
    my @files = @_ ? @_ : all_pm_files();

    $Test->plan(tests => scalar @files);

    my $ok = 1;
    for (@files) {
        pm_file_ok($_) or undef $ok;
    }
    $ok;
}


sub all_pm_files {
    my @queue = @_ ? @_ : _starting_points();
    my @pm;

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
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
    return @pm;
}


sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}


1;

__END__

#line 261

