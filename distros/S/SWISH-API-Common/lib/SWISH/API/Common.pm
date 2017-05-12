###########################################
# SWISH::API::Common
###########################################

###########################################
package SWISH::API::Common;
###########################################

use strict;
use warnings;

our $VERSION         = "0.04";
our $SWISH_EXE       = "swish-e";
our @SWISH_EXE_PATHS = qw(/usr/local/bin);

use SWISH::API;
use File::Path;
use File::Find;
use File::Spec;
use File::Basename;
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(:all);
use File::Temp qw(tempfile);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        swish_adm_dir             => "$ENV{HOME}/.swish-common",
        swish_exe                 => swish_find(),
        swish_fuzzy_indexing_mode => "Stemming_en",
        %options,
    };

    my $defaults = {
        swish_idx_file   => "$self->{swish_adm_dir}/default.idx",
        swish_cnf_file   => "$self->{swish_adm_dir}/default.cnf",
        dirs_file        => "$self->{swish_adm_dir}/default.dirs",
        streamer         => "$self->{swish_adm_dir}/default.streamer",
        file_len_max     => 100_000,
        atime_preserve   => 0,
    };

    for my $name (keys %$defaults) {
        if(! exists $self->{$name}) {
            $self->{$name} = $defaults->{$name};
        }
    }

    LOGDIE "swish-e executable not found" unless -x $self->{swish_exe};

    bless $self, $class;
}

###########################################
sub index_remove {
###########################################
    my($self) = @_;

    unlink $self->{swish_idx_file};
}

###########################################
sub search {
###########################################
    my($self, $term) = @_;

    if(! -f $self->{swish_idx_file}) {
        ERROR "Index file $self->{swish_idx_file} not found";
        return undef;
    }

    my $swish = SWISH::API->new($self->{swish_idx_file});

    $swish->AbortLastError 
        if $swish->Error;

    my $results = $swish->Query($term);

    $swish->AbortLastError 
        if $swish->Error;

       # We might change this in the future to return an iterator
       # in scalar context
    my @results = ();

    while (my $r = $results->NextResult) {
        my $hit = SWISH::API::Common::Hit->new(
                      path => $r->Property("swishdocpath")
                  );
        push @results, $hit;
    }

    return @results;
}

###########################################
sub files_stream {
###########################################
    my($self) = @_;

    my @dirs = split /,/, slurp $self->{dirs_file};

    my @files = grep { -f } @dirs;
       @dirs  = grep { ! -f } @dirs;

    for(@files) {
        $self->file_stream($_);
    }

    return unless @dirs;

    find(sub {
        return unless -f;
        return unless -T;

        my $full = $File::Find::name;

        DEBUG "Indexing $full";
        $self->file_stream(File::Spec->rel2abs($_));

    }, @dirs);
}

############################################
sub file_stream {
############################################
    my($self, $file) = @_;

    my @saved;

    if($self->{atime_preserve}) {
        @saved = (stat($file))[8,9];
    }

    if(! open FILE, "<$file") {
        WARN "Cannot open $file ($!)";
        return;
    }

    my $rc = sysread FILE, my $data, $self->{file_len_max};

    unless(defined $rc) {
        WARN "Can't read $file $!";
        return;
    }
    close FILE;

    if($self->{atime_preserve}) {
        utime(@saved, $file);
    }

    my $size = length $data;

    print "Path-Name: $file\n",
          "Document-Type: TXT*\n",
          "Content-Length: $size\n\n";
    print $data;
}

############################################
sub dir_prep {
############################################
    my($file) = @_;

    my $dir = dirname($file);

    if(! -d $dir) {
        mkd($dir) unless -d $dir;
    }
}

############################################
sub index_add {
############################################
    my($self, $dir) = @_;

        # Index new doc in tmp idx file
    my $old_idx_name = $self->{swish_idx_file};
    (my $dummy, my $old_idx) = tempfile(CLEANUP => 1);
    mv $old_idx_name, $old_idx;
    mv "$old_idx_name.prop", "$old_idx.prop";

    ($dummy, $self->{swish_idx_file}) = tempfile(CLEANUP => 1);
    $self->index($dir);

        # Merge two indices
    my($stdout, $stderr, $rc) = tap($self->{swish_exe}, "-M",
                                    $old_idx,
                                    $self->{swish_idx_file},
                                    $old_idx_name);

    if($rc != 0) {
        ERROR "Merging failed: $stdout $stderr";
        return undef;
    }

    $self->{swish_idx_file} = $old_idx_name;
}

############################################
sub index {
############################################
    my($self, @dirs) = @_;

        # Make a new dirs file
    dir_prep($self->{dirs_file});
    blurt join(',', @dirs), $self->{dirs_file};

        # Make a new swish conf file
    dir_prep($self->{swish_cnf_file});
    blurt <<EOT, $self->{swish_cnf_file};
IndexDir  $self->{streamer}
IndexFile $self->{swish_idx_file}
FuzzyIndexingMode $self->{swish_fuzzy_indexing_mode}
EOT

        # Make a new streamer
    dir_prep($self->{streamer});
    my $perl = perl_find();
    blurt <<EOT, $self->{streamer};
#!$perl
use SWISH::API::Common;
SWISH::API::Common->new(
        dirs_file    => '$self->{dirs_file}',
        file_len_max => '$self->{file_len_max}',
)->files_stream();
EOT

    chmod 0755, $self->{streamer} or 
        LOGDIE "chmod of $self->{streamer} failed ($!)";

    my($stdout, $stderr, $rc) = tap($self->{swish_exe}, "-c",
                                    $self->{swish_cnf_file},
                                    "-e", "-S", "prog");

    unless($stdout =~ /Indexing done!/) {
        ERROR "Indexing failed: $stdout $stderr";
        return undef;
    }

    DEBUG "$stdout";

    1;
}

###########################################
sub perl_find {
###########################################

    if($^X =~ m#/#) {
        return $^X;
    }

    return exe_find($^X);
}

###########################################
sub swish_find {
###########################################

    for my $path (@SWISH_EXE_PATHS) {
        if(-f File::Spec->catfile($path, $SWISH_EXE)) {
                return File::Spec->catfile($path, $SWISH_EXE);
        }
    }

    return exe_find($SWISH_EXE);
}

###########################################
sub exe_find {
###########################################
    my($exe) = @_;

    for my $path (split /:/, $ENV{PATH}) {
        if(-f File::Spec->catfile($path, $exe)) {
                return File::Spec->catfile($path, $exe);
        }
    }

    return undef;
}

###########################################
package SWISH::API::Common::Hit;
###########################################

make_accessor(__PACKAGE__, "path");

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        %options,
    };

    bless $self, $class;
}

##################################################
# Poor man's Class::Struct
##################################################
sub make_accessor {
##################################################
    my($package, $name) = @_;

    no strict qw(refs);

    my $code = <<EOT;
        *{"$package\\::$name"} = sub {
            my(\$self, \$value) = \@_;
    
            if(defined \$value) {
                \$self->{$name} = \$value;
            }
            if(exists \$self->{$name}) {
                return (\$self->{$name});
            } else {
                return "";
            }
        }
EOT
    if(! defined *{"$package\::$name"}) {
        eval $code or die "$@";
    }
}

1;

__END__

=head1 NAME

SWISH::API::Common - SWISH Document Indexing Made Easy

=head1 SYNOPSIS

    use SWISH::API::Common;

    my $swish = SWISH::API::Common->new();

        # Index all files in a directory and its subdirectories
    $swish->index("/usr/local/share/doc");

        # After indexing once (it's persistent), fire up as many
        # queries as you like:

        # Search documents containing both "swish" and "install"
    for my $hit ($swish->search("swish AND install")) {
        print $hit->path(), "\n";
    }

=head1 DESCRIPTION

C<SWISH::API::Common> offers an easy interface to the Swish index engine.
While SWISH::API offers a complete API, C<SWISH::API::Common> focusses
on ease of use. 

THIS MODULE IS CURRENTLY UNDER DEVELOPMENT. THE API MIGHT CHANGE AT ANY
TIME.

Currently, C<SWISH::API::Common> just allows for indexing documents
in a single directory and any of its subdirectories. Also, don't run
index() and search() in parallel yet.

=head1 INSTALLATION

C<SWISH::API::Common> requires C<SWISH::API> and the swish engine to
be installed. Please download the latest release from 

    http://swish-e.org/distribution/swish-e-2.4.3.tar.gz

and untar it, type

    ./configure
    make
    make install

and then install SWISH::API which is contained in the distribution:

    cd perl
    perl Makefile.PL
    make 
    make install

=head2 METHODS

=over 4

=item $sw = SWISH::API::Common-E<gt>new()

Constructor. Takes many options, but the defaults are usually fine.

Available options and their defaults:

        # Where SWISH::API::Common stores index files etc.
    swish_adm_dir   "$ENV{HOME}/.swish-common"

        # The path to swish-e, relative is OK
    swish_exe       "swish-e"

        # Swish index file
    swish_idx_file  "$self->{swish_adm_dir}/default.idx"

        # Swish configuration file
    swish_cnf_file  "$self->{swish_adm_dir}/default.cnf"

        # SWISH Stemming
    swish_fuzzy_indexing_mode => "Stemming_en"

        # Maximum amount of data (in bytes) extracted
        # from a single file
    file_len_max 100_000

        # Preserve every indexed file's atime
    atime_preserve
        
=item $sw-E<gt>index($dir, ...)

Generate a new index of all text documents under directory C<$dir>. One
 or more directories can be specified.

=item $sw-E<gt>search("foo AND bar");

Searches the index, using the given search expression. Returns a list
hits, which can be asked for their path:

        # Search documents containing 
        # both "foo" and "bar"
    for my $hit ($swish->search("foo AND bar")) {
        print $hit->path(), "\n";
    }

=item index_remove

Permanently delete the current index.

=back 

=head1 TODO List

    * More than one index directory
    * Remove documents from index
    * Iterator for search hits

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
