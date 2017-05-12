# Copyright (C) 2005  Joshua Hoblitt
#
# $Id: Tidy.pm,v 1.27 2009/02/17 21:49:37 jhoblitt Exp $

package Pod::Tidy;

use strict;
use warnings FATAL => qw( all );

use vars qw( $VERSION $columns );
$VERSION = '0.10';

use Fcntl ':flock';
use File::Basename qw( basename dirname );
use File::Spec;
use IO::String;
use File::Copy qw( cp );
use Pod::Find qw( contains_pod );
use Pod::Simple;
use Pod::Wrap::Pretty;
use Text::Wrap qw($columns);

# Text::Wrap's default is 76, we are using 80 to maintain compatability with
# Pod::Tidy <= 0.09
$columns = 80;

use vars qw( $BACKUP_POSTFIX);
# used by backup_file
$BACKUP_POSTFIX = "~";

sub tidy_files
{
    my %p = @_;

    $columns = $p{columns} if $p{columns};

    my $queue = build_pod_queue(
        files       => $p{files},
        ignore      => $p{ignore},
        recursive   => $p{recursive},
        verbose     => $p{verbose},
    );

    return undef unless $queue;

    return process_pod_queue(
        inplace     => $p{inplace},
        nobackup    => $p{nobackup},
        queue       => $queue,
    ); 
}

sub tidy_filehandle
{
    my $input = shift;

    return undef unless $input;

    my $wrapper = Pod::Wrap::Pretty->new;
    $wrapper->parse_from_filehandle($input);

    return 1;
}

sub process_pod_queue 
{
    my %p = @_;

    my $verbose     = $p{verbose};
    my $inplace     = $p{inplace};
    my $queue       = $p{queue};
    my $nobackup    = $p{nobackup};

    return undef unless defined $queue;

    # count the number of files processed
    my $processed = 0;
    my $wrapper = Pod::Wrap::Pretty->new;

    foreach my $filename (@{ $queue }) {
        # all files in queue should have already been checked to be readable
        open(my $src, '+<', $filename) or warn "can't open file: $!" && next;

        # wait for an exclusive lock in case we want to modify the file
        flock($src, LOCK_EX);

        # slurp the file into memory to avoid making a tmp file
        my $doc = do { local $/; <$src> };

        # wrap the doc with a file handle
        my $input = IO::String->new($doc);

        # modify in place?
        if ($inplace) {
            my $output = IO::String->new;
            $wrapper->parse_from_filehandle($input, $output);

            # leave the mtime alone if we didn't change anything
            next if ${$input->string_ref} eq ${$output->string_ref};

            # backup existing file
            unless ($nobackup) {
                backup_file($filename);
            }

            # overwrite the original file
            truncate($src, 0);
            seek($src, 0, 0);
            print $src ${$output->string_ref};
        } else {
            # send the output to STDOUT
            $wrapper->parse_from_filehandle($input);
        }

        # count of files actually processed
        # note that this number will be different for 'inplace' as unmodified
        # files will not be counted
        $processed++;
    }

    return $processed;
}

sub build_pod_queue
{
    my %p = @_;

    # deref once
    my $verbose     = $p{verbose};
    my $recursive   = $p{recursive};
    my $ignore      = $p{ignore};

    my @queue;
        PERITEM: foreach my $item (@{ $p{files} }) {
        # FIXME do we need to add symlink handling options?
        $item = File::Spec->canonpath($item);

        foreach my $pattern (@{ $ignore }) {
            # try the absolute path, then the relative path, then the 'base'
            # path
            if (
                    (File::Spec->rel2abs($item) =~ $pattern)
                    or                  ($item  =~ $pattern)
                    or             (base($item) =~ $pattern)
               ) {
                warn "$0: omitting file \`$item\': matches ignore pattern: "
                    . "$pattern\n" if $verbose;
                next PERITEM;
            }
        }
        
        # is it a file?
        if (-f $item) {
            # only check if we can read the file, we don't need to be able to
            # write to it unless we're doing an inplace edit
            unless (-r $item) {
                warn "$0: omitting file \`$item\': permission denied\n";
                next;
            }

            unless (contains_pod($item, 0)) {
                warn "$0: omitting file \`$item\': does not contain Pod\n"
                    if $verbose;
                next;
            }

            unless (valid_pod_syntax($item, $verbose)) {
                warn "$0: omitting file \`$item\': bad Pod syntax\n"
                    if $verbose;
                next;
            }

            push @queue, $item;

            next;
        } 

        # is it a dir?
        if (-d $item) {
            unless (-r $item and -x $item) {
                warn "$0: omitting file \`$item\': permission denied\n";
                next;
            }

            # is recursion allowed?
            if ($recursive) {
                # It may be better to use File::Find or Pod::Find here.
                # Initialiy I was using Pod::Find but I wanted explict control
                # over warnings.
                opendir(my $dir, $item) or warn "can't open dir: $!" && next;
                my @files = grep !/^\.{1,2}$/, readdir($dir);
                @files = map { "$item/$_" } @files;
                my $pod_list = build_pod_queue(
                    files       => \@files,
                    verbose     => $verbose,
                    recursive   => $recursive,
                    ignore      => $ignore,
                );
                push(@queue, @{ $pod_list }) if $pod_list;
            } else {
                # ignoring $item, recursion not enabled
            warn "$0: omitting direcotry \`$item\': recursion is not enabled\n" 
                if $verbose;
            }
            next;
        }

        # it must be bogus
        warn "$0: \`$item\': no such file or directory\n" if $verbose;
    }

    return scalar @queue ? \@queue : undef;
}

sub valid_pod_syntax
{
    my ($filename, $verbose) = @_;

    return undef unless defined $filename and -e $filename;

    # method for checking syntax stolen from Test::Pod
    my $parser = Pod::Simple->new;

    $parser->complain_stderr(1) if $verbose;
    $parser->parse_file($filename);

    return $parser->any_errata_seen ? undef : 1;
}

sub backup_file
{
    my $filename = shift;

    return undef unless defined $filename and -e $filename;
    return cp($filename, $filename . $BACKUP_POSTFIX);
}

sub base
{
    my $path = shift;

    if (my $base = basename($path)) {
        return $base;
    } else {
        return basename(dirname($path));
    }
}

1;

__END__
