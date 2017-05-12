package PPI::Xref;

require v5.14;  # 5.10: defined-or; 5.14: package Sub { ... }

our $VERSION = '0.010';

use strict;
use warnings;

use PPI;

# We will use file ids (integers) instead of filenames, mainly for
# space savings, but also speed, and only convert back to filenames
# on leaving the API boundary.
my $FILE_ID = 0;
my %FILE_BY_ID;

my %CTOR_OPTS =
    map { $_ => 1} qw/process_verbose cache_verbose recurse_verbose
                      recurse INC
                      cache_directory
                      cache_read_only
                      cache_portable_filenames
                      __allow_relative/;

my $HASHALGO = 'sha1';

package Sub {  # For getting the current sub name.
    sub TIESCALAR { bless \$_[1], $_[0] }
    sub FETCH { (caller(1))[3] }
}
tie my $Sub, 'Sub';

sub __is_readwrite_directory {
    my ($self, $dir) = @_;
    return -d $dir && -r $dir && -w $dir;
}

# Our constructor.
sub new {
    my ($class, $opt) = @_;
    $opt //= {};
    # In the opt you can specify:
    # - process_verbose: for process progress
    # - cache_verbose: for cache activity
    # - recurse_verbose: for recurse, show revisits
    # - INC: an aref for a custom @INC
    # - recurse: or not (default: yes)
    # - cache_directory: directory where the cache is
    # - cache_read_only: only read the cache
    # - cache_portable_filanmes: avoid multiple dots in cache filenames

    $opt->{recurse} //= 1;

    my %unexpopt = %$opt;
    delete @unexpopt{keys %CTOR_OPTS};

    for my $k (sort keys %unexpopt) {
        warn "$Sub: unexpected option: $k\n";
    }

    my $self = { opt => $opt };

    my $cache_directory = $opt->{cache_directory};
    if (defined $cache_directory) {
        unless (PPI::Xref->__is_readwrite_directory($cache_directory)) {
            warn "$Sub: cache_directory '$cache_directory': not a read-write directory\n";
        }

        $self->{__cache_prefix_length} = length($cache_directory) + 1;

        use Sereal::Encoder;
        use Sereal::Decoder;
        $self->{encoder} = Sereal::Encoder->new;
        $self->{decoder} = Sereal::Decoder->new;
    }

    bless $self, $class;
}

# Unless $self->{inc_dirs} is set, set it from either opt INC, if set,
# or from the system @INC.
sub __inc_dirs {
    my $self = shift;
    unless (defined $self->{inc_dirs}) {
        for my $d ($self->{opt}{INC} ? @{ $self->{opt}{INC}} : @INC) {
            next if ref $d;
            next unless -d $d && -x $d;
            push @{ $self->{inc_dirs} }, $d;
        }
    }
}

sub PPI::Xref::INC {
    my $self = shift;
    $self->__inc_dirs;
    return $self->{inc_dirs};
}

# Given a file, look for it in @INC.
sub __find_file {
    my ($self, $file) = @_;
    $self->__inc_dirs;
    unless (exists $self->{inc_file}{$file}) {
        for my $d (@{ $self->{inc_dirs}}) {
            unless ($self->{opt}{__allow_relative}) {  # For testing.
                use File::Spec;
                $d = File::Spec->rel2abs($d) unless
                    File::Spec->file_name_is_absolute($d);
            }
            my $f = "$d/$file";
            if (-f $f) {
                $self->{inc_file}{$file} = $f;
                last;
            }
        }
        unless (exists $self->{inc_file}{$file}) {
            $self->{inc_file}{$file} = undef;
        }
    }
    return $self->{inc_file}{$file};
}

# Given a module name, look for its file in @INC.
sub __find_module {
    my ($self, $module_name) = @_;
    unless (exists $self->{module_file}{$module_name}) {
        my $m = $module_name;
        $m =~ s{::}{/}g;
        $m .= '.pm';
        $self->{module_file}{$module_name} = $self->__find_file($m);
    }
    return $self->{module_file}{$module_name};
}

# Remove comments and tokens, and squeeze
# multiple whitespaces into one.
sub __normalize_whitespace {
    my @n;
    my $prev_ws;
    my $curr_ws;
    for my $n (@_) {
        next if $n->isa('PPI::Token::Comment');
        next if $n->isa('PPI::Token::Pod');
        $curr_ws = $n->isa('PPI::Token::Whitespace');
        next if $prev_ws && $curr_ws;
        push @n, $n;
        $prev_ws = $curr_ws;
    }
    return @n;
}

# For a filename, assign it a file id (an integer) if it does not
# have one, and in any case return its file id.
sub __assign_file_id {
    my ($self, $filename) = @_;
    my $file_id = $self->{file_id}{$filename};
    unless (defined $file_id) {
        $file_id = $self->{file_id}{$filename} = $FILE_ID++;
        $FILE_BY_ID{$file_id} = $filename;
    }
    return $file_id;
}

# Close the current package, if any.
sub __close_package {
    my ($self, $file_id, $package, $elem) = @_;
    if (exists $self->{file_packages} &&
        ref $self->{file_packages}{$file_id} &&
        @{ $self->{file_packages}{$file_id} }) {
        push @{ $self->{file_packages}{$file_id}[-1] },
             $elem->line_number,
             $elem->column_number;
    }
}

# Open a new package.
sub __open_package {
    my ($self, $file_id, $package, $elem) = @_;
    push @{ $self->{file_packages}{$file_id} },
         [
          $package,             # 0
          $elem->line_number,   # 1
          $elem->column_number, # 2
         ];
}

# Close the current package, if any, and open a new one.
sub __close_open_package {
    my ($self, $file_id, $old_package, $old_elem,
        $new_package, $new_elem, $fileloc) = @_;
    if (defined $old_package && $old_package ne 'main') {
        $self->__close_package($file_id, $old_package, $old_elem, $fileloc);
    }
    $self->__open_package($file_id, $new_package, $new_elem);
}

# Function for portably turning the directory portion of a pathname
# into a directory name.  If the $flatten_volume is true, loses
# information in platforms that have a volume name in pathnames, but
# the main idea is to safely split the argument into a new directory
# name (possibly modified by prepending the volume name as a
# directory), and the filename.  E.g.  '/a/b/c' -> ('/a/b', 'c')
# 'c:/d/e' -> ('/c/d', 'e')
sub __safe_vol_dir_file {
    my ($self, $path, $flatten_volume) = @_;
    my ($vol, $dirs, $file) =  File::Spec->splitpath($path);
    if ($flatten_volume && $^O eq 'MSWin32') {
      $vol =~ s/:$//;  # splitpath() leaves the $vol as e.g. "c:"
    }
    return (File::Spec->catpath($vol, $dirs), $file);
}

# Returns the directory part and the file part.  Note that this will
# convert the volume name (if any) in the $path into a directory name,
# e.g. 'c:/d/e' -> ('/c/d', 'e').  This is useful for re-rooting
# a pathname under a new directory.
sub __safe_dir_and_file_flatten_volume {
  my ($self, $path) = @_;
  return $self->__safe_vol_dir_file($path, 1);
}

# Returns the directory part (with the possible volume part prepended)
# and the file part.  Kind of like a safe dirname().
sub __safe_dir_and_file_same_volume {
  my ($self, $path) = @_;
  return $self->__safe_vol_dir_file($path, 0);
}

my $CACHE_EXT = '.cache';

# "shadow file" is a filename rooted into a new, "shadow", directory.
sub __shadow_cache_filename {
    my ($self, $shadowdir, $filename) = @_;

    # Paranoia check.  (Either absolute or relative is fine, though.)
    if ($filename =~ m{\.\.}) {
        warn "$Sub: Skipping unexpected file: '$filename'\n";
        return;
    }

    use File::Spec;
    my $absfile =
        File::Spec->file_name_is_absolute($filename) ?
        $filename :
        File::Spec->rel2abs($filename);
    my ($redir, $file) = $self->__safe_dir_and_file_flatten_volume($absfile);

    if ($self->{opt}{cache_portable_filenames}) {
        # For portable filenames, we cannot just keep on
        # appending filename extensions with dots, and we
        # are going to append the cache filename extension.
        # So we mangle the .pm or .pl as _pm and _pl.
        $file =~ s{\.(p[ml])$}{_$1};
    }

    return File::Spec->catfile($shadowdir, $redir, $file . $CACHE_EXT);
}

# The hash checksum for the file, and the mtime timestamp.
sub __current_filehash_and_mtime {
    my ($self, $origfilename) = @_;
    return unless -f $origfilename;
    my $origfilefh;
    unless (open($origfilefh, $origfilename)) {
        warn qq[$Sub: Failed to open "$origfilename": $!\n];
        return;
    }
    use Digest::SHA;
    my $sha = Digest::SHA->new($HASHALGO);
    $sha->addfile($origfilefh);
    return (
        "$HASHALGO:". $sha->hexdigest,
        (stat($origfilefh))[9], # mtime
        );
}

# Create the directory of the filename.
sub __make_path_file {
    my ($self, $base) = @_;
    use File::Path qw[make_path];
    my ($dir, $file) = $self->__safe_dir_and_file_same_volume($base);
    return eval { make_path($dir) unless -d $dir; 1; };
}

# The attributes that are written to and read from cache.
my @CACHE_FIELDS =
    qw[
       file_incs
       file_lines
       file_modules
       file_packages
       file_subs
       file_missing_modules
       file_parse_errors
      ];

# Error fields are cache fields but they should not be cleared
# since they accumulate and are hrefs as opposed to arefs.
my %CACHE_FIELDS_KEEP =
    map { $_ => 1 }
    qw[
       file_missing_modules
       file_parse_errors
      ];

my @CACHE_FIELDS_CLEAR =
    grep { ! exists $CACHE_FIELDS_KEEP{$_} } @CACHE_FIELDS;

# Given the href, serialize it to the file.
sub __encode_to_file {
    my ($self, $file, $cached) = @_;

    my $success = 0;

    my $temp = "$file.$$";  # For atomic renaming.

    # If anything goes wrong, abort the commit.
  COMMIT: {
      my $blob = $self->{encoder}->encode($cached);
      unless (defined $blob) {
          warn "$Sub: Failed to encode into '$temp'\n";
          last COMMIT;
      }

      unless ($self->__make_path_file($temp)) {
          warn "$Sub: Failed to create path for '$temp'\n";
          last COMMIT;
      }

      my $fh;
      use Fcntl qw[O_CREAT O_WRONLY];
      unless (sysopen($fh, $temp, O_CREAT|O_WRONLY, 0644)) {
          warn "$Sub: Failed to open '$temp' for writing: $!\n";
          last COMMIT;
      }

      my $size = length($blob);
      my $wrote = syswrite($fh, $blob);

      unless (defined $wrote && $wrote == $size) {
          warn "$Sub: Failed to write $size bytes to '$temp': $!\n";
          last COMMIT;
      }

      unless (close($fh)) {
          warn "$Sub: Failed to close '$temp': $!\n";
          last COMMIT;
      }

      unless (rename($temp, $file)) {
          warn "$Sub: Failed to rename '$temp' as '$file': !$\n";
          last COMMIT;
      }

      # Finally we are happy.
      $success = 1;

    }  # COMMIT

    if (-f $temp) {
        warn "$Sub: Cleaning temporary file '$temp'\n";
    }
    unlink $temp;   # In any case.

    return $success;
}

# Write the results to the file.
sub __write_cachefile {
    my ($self, $cache_filename, $hash_current, $file_id, $file_mtime) = @_;

    return if $self->{opt}{cache_read_only};

    if ($self->{opt}{cache_verbose}) {
        print "$Sub: writing $cache_filename\n";
    }

    my $cached;  # Re-root the data we care about.
    for my $k (@CACHE_FIELDS) {
        if (defined $self->{$k}{$file_id}) {
            $cached->{$k} = $self->{$k}{$file_id};
        }
    }
    $cached->{file_hash} = $hash_current;

    # The mtime is in UTC, and should only be used for
    # maintenance / statistics.  In other words, it should
    # NOT be used for uptodateness.
    $cached->{file_mtime} = $file_mtime;

    # Mark also in the object that we have processed this one.
    $self->{file_hash}{$file_id} = $hash_current;

    return $self->__encode_to_file($cache_filename, $cached);
}

# Compose a cache filename, given an original filename.
# The filenames are re-rooted in the cache_directory.
sub __cache_filename {
    my ($self, $path) = @_;
    return if $path eq '-';

    my $cache_directory = $self->{opt}{cache_directory};
    return unless defined $cache_directory;

    unless ($self->__is_readwrite_directory($cache_directory)) {
        warn "$Sub: Not a read-write directory '$cache_directory'\n";
        return;
    }

    if ($path !~ /\.p[ml]$/) {
        warn "$Sub: Unexpected filename: '$path'\n";
        return;
    }

    return $self->__shadow_cache_filename($cache_directory, $path);
}

# Deserialize from the file.
sub __decode_from_file {
    my ($self, $file) = @_;

    my $fh;
    use Fcntl qw[O_RDONLY];
    unless (sysopen($fh, $file, O_RDONLY)) {
        # warn "$Sub: Failed to open '$file' for reading: $!\n";
        return;
    }

    my $size = -s $fh;
    my $read = sysread($fh, my $blob, $size);
    unless ($read == $size) {
        warn "$Sub: Failed to read $size bytes from '$file': $!\n";
        return;
    }

    return $self->{decoder}->decode($blob);
}

# Check if we have the results for this file cached.
sub __check_cached {
    my ($self, $origfile) = @_;
    return if $origfile eq '-';

    my ($hash_current, $file_mtime) =
        $self->__current_filehash_and_mtime($origfile);
    my $cache_directory = $self->{opt}{cache_directory};
    my $cache_filename;
    my $cached;
    my $hash_previous;
    my $hash_match;

    if (defined $cache_directory) {
        $cache_filename = $self->__cache_filename($origfile);
        if (defined $cache_filename) {
            if ($self->{opt}{cache_verbose}) {
                print "$Sub: reading $cache_filename\n";
            }
            $cached = $self->__decode_from_file($cache_filename);
            if (defined $cached) {
                if ($self->{opt}{cache_verbose}) {
                    print "$Sub: reading $cache_filename SUCCESS\n";
                }
                $hash_previous = $cached->{file_hash};
                $hash_match =
                    defined $hash_previous &&
                    defined $hash_current &&
                    $hash_previous eq $hash_current;
            } else {
                if ($self->{opt}{cache_verbose}) {
                    print "$Sub: reading $cache_filename FAILURE\n";
                }
            }
        }
    }

    return ($cache_filename,
            $cached,
            $hash_current,
            $hash_match,
            $file_mtime);
}

# Write to the cache and tick various counters.
sub __to_cache {
    my ($self, $cache_filename, $hash_current, $file_id, $file_mtime) = @_;

    return if $self->{opt}{cache_read_only};

    my $had_cache = -f $cache_filename;
    if ($self->__write_cachefile($cache_filename, $hash_current,
                                 $file_id, $file_mtime)) {
        if ($self->{opt}{cache_verbose}) {
            print "$Sub: writing $cache_filename SUCCESS\n";
        }
        $self->{__cachewrites}++;
        unless ($had_cache) {
            $self->{__cachecreates}++;
        }
    } else {
        if ($self->{opt}{cache_verbose}) {
            print "$Sub: writing $cache_filename FAILURE\n";
        }
    }
}

# Import the fields we care about from the cached data.
sub __import_cached {
    my ($self, $file_id, $cached) = @_;

    for my $k (@CACHE_FIELDS) {
        $self->{$k}{$file_id} = $cached->{$k};
    }

    return 1;
}

# Clear the cached fields.  Used especially in preparation of import.
sub __clear_cached {
    my ($self, $file_id) = @_;

    for my $k (@CACHE_FIELDS_CLEAR) {
        delete $self->{$k}{$file_id};
    }

    return 1;
}

sub __parse_error {
    my ($self, $file_id, $file, $fileloc, $error) = @_;
    if (defined $fileloc) {
       warn qq[$Sub: $error in $fileloc\n];
    } else {
       warn qq[$Sub: $error\n];
    }
    $self->{file_parse_errors}{$file_id}{$fileloc // $file} = $error;
}

sub __doc_create {
    my ($self, $arg, $file, $file_id) = @_;
    my $doc;
    eval { $doc = PPI::Document->new($arg) };
    unless (defined $doc) {
        $self->__parse_error($file_id, $file, $file,
                             "PPI::Document creation failed");
    } else {
        my $complete;
        eval { $complete = $doc->complete };
        unless ($complete) {
            my $pseudo = $file eq '-';
            if (!$pseudo && ! -f $file) {
                $self->__parse_error($file_id, $file, undef,
                                     "Missing file");
            } elsif (!$pseudo && ! -s $file) {
                $self->__parse_error($file_id, $file, undef,
                                     "Empty file");
            } else {
                $self->__parse_error($file_id, $file, $file,
                                     "PPI::Document incomplete");
            }
        }
    }
    return $doc;
}

# Process a given filename.
sub __process_file {
    my ($self, $arg, $file, $process_depth) = @_;
    $file //= $arg;
    $self->{file_counts}{$file}++;
    if ($file eq '-') {  # Pseudofile.
        if ($self->{opt}{process_verbose}) {
            printf "$Sub: %*s%s\n", $process_depth + 1, ' ', $file;
        }
        my $file_id = $self->__assign_file_id($file);
        my $doc = $self->__doc_create($arg, $file, $file_id);
        return unless defined $doc;
        $self->{__docscreated}++;
        $self->__process_id($doc, $file_id, $process_depth);
    } elsif ($self->{seen_file}{$file}) {
        if ($self->{opt}{process_verbose} && $self->{opt}{recurse_verbose}) {
            printf "$Sub: %*s%s [seen]\n", $process_depth + 1, ' ', $file;
        }
    } elsif (! $self->{seen_file}{$file}++) {
        if ($self->{opt}{process_verbose}) {
            printf "$Sub: %*s%s\n", $process_depth + 1, ' ', $file;
        }
        my $file_id = $self->__assign_file_id($file);
        my ($cache_filename, $cached, $hash_current,
            $hash_match, $file_mtime) =
            $self->__check_cached($file);
        if ($hash_match) {
            $self->__clear_cached($file_id);
            $self->__import_cached($file_id, $cached);
            $self->__process_cached_incs($file_id, $process_depth);
            $self->{__cachereads}++;
        } elsif (!$self->{opt}{cache_read_only}) {
            my $doc = $self->__doc_create($arg, $file, $file_id);
            return unless defined $doc;
            $self->__clear_cached($file_id);
            $self->__process_id($doc, $file_id, $process_depth);
            $self->{__docscreated}++;
        }
        if (defined $cache_filename &&
            defined $hash_current &&
            !$hash_match &&
            !$self->{opt}{cache_read_only}) {
            if ($self->__to_cache($cache_filename, $hash_current,
                                  $file_id, $file_mtime)) {
                if (!$hash_match && defined $cached) {
                    $self->{__cacheupdates}++;
                }
            }
        }
    }
    return $self->{file_id}{$file};
}

# Counter getters.

sub docs_created {
    my ($self) = @_;
    return $self->{__docscreated} // 0;
}

sub cache_reads {
    my ($self) = @_;
    return $self->{__cachereads} // 0;
}

sub cache_writes {
    my ($self) = @_;
    return $self->{__cachewrites} // 0;
}

sub cache_creates {
    my ($self) = @_;
    return $self->{__cachecreates} // 0;
}

sub cache_updates {
    my ($self) = @_;
    return $self->{__cacheupdates} // 0;
}

sub cache_deletes {
    my ($self) = @_;
    return $self->{__cachedeletes} // 0;
}

# For results imported from cache, process any cached inclusions.
# The [6] is the include file, the [7] will become its (new) file id.
sub __process_cached_incs {
    my ($self, $file_id, $process_depth) = @_;
    for my $inc (@{ $self->{file_incs}{$file_id} }) {
        my $include_file = $inc->[6];
        $self->__process_file($include_file, undef,
                              $process_depth + 1);
        $inc->[7] = $self->{file_id}{$include_file};
    }
}

# For freshly computed results, process any cached inclusions.
# The [6] is the include file, the [7] will become its (new) file id.
sub __process_pending_incs {
    my ($self, $file_id, $process_depth) = @_;
    if ($self->{__incs_flush}{$file_id}) {
        $self->{file_incs}{$file_id} =
            delete $self->{__incs_pending}{$file_id};
        for my $inc (@{ $self->{file_incs}{$file_id} }) {
            my $include_file = $inc->[6];
            $self->__process_file($include_file, undef,
                                  $process_depth + 1);
            $inc->[7] = $self->{file_id}{$include_file};
        }
        delete $self->{__incs_flush}{$file_id};  # Defuse the trigger.
    }
}

# Process a given PPI document, that has a given file id.
sub __process_id {
    my ($self, $doc, $file_id, $process_depth) = @_;
    my @queue = @{$doc->{children}};
    my $scope_depth = 0;
    my %package = ( 0 => 'main' );
    my $package = $package{$scope_depth};
    my $prev_package;
    my $elem;
    my $prev_elem;
    my $filename = $FILE_BY_ID{$file_id};
    my $fileloc;
    while (@queue) {
        $elem = shift @queue;
        my $linenumber = $elem->line_number;
        $fileloc = "$filename:$linenumber";
        if (0) {
            printf("$fileloc elem = %s[%s]\n",
                   $filename, ref $elem, $elem->content);
        }
        my @children = exists $elem->{children} ?
            __normalize_whitespace(@{$elem->{children}}) : ();
        if ($elem->isa('PPI::Token::Structure')) {
            # { ... }
            if ($elem->content eq '{') {
                $scope_depth++;
            } elsif ($elem->content eq '}') {
                if ($scope_depth <= 0) {
                    $self->__parse_error($file_id, $filename, $fileloc,
                                         "scope pop underflow");
                } else {
                    $scope_depth--;
                    delete @package{ grep { $_ > $scope_depth } keys %package };
                    use List::Util qw[first];
                    $package =
                        $package{$scope_depth} //
                        first { defined } @package{reverse 0..$scope_depth};
                    if (defined $prev_package && $package ne $prev_package) {
                        if (0) {
                            print "$fileloc: package change: $prev_package -> $package\n";
                        }
                        $self->__close_open_package(
                            $file_id, $prev_package, $prev_elem,
                            $package, $elem);
                    }
                }
            }
        }
        if (@children) {
            if ($elem->isa('PPI::Statement::Package') && @children >= 2) {
                # package ...
                #
                # Remember to test 'use mro' and look for next::can().
                $package = $children[2]->content;
                $package{$scope_depth} = $package;
                if (defined $package && length $package) {
                    # Okay, keep going.
                } else {
                    $self->__parse_error($file_id,
                                         $filename,
                                         $fileloc, "missing package");
                }
                if (defined $prev_package) {
                    if ($package ne $prev_package) {
                        if (0) {
                            print "$fileloc: package change: $prev_package -> $package\n";
                        }
                        $self->__close_open_package(
                            $file_id, $prev_package, $prev_elem,
                            $package, $elem);
                    }
                } else {
                    if (0) {
                        print "$fileloc: package first: $package\n";
                    }
                    $self->__open_package($file_id, $package, $elem);
                }
            } elsif ($elem->isa('PPI::Statement::Sub') &&
                     defined $elem->name &&
                     !$elem->forward  # Not a forward declaration.
                ) {
                # sub ...
                my $sub = $elem->name;
                unless ($sub =~ /::/) {  # sub x::y::z { ... }
                    $package //= 'main';
                    $sub = $package . '::' . $sub;
                }
                my $finish = $elem->block->finish;
                unless (defined $finish) {
                    # E.g. Devel::Peek:debug_flags() fails to have a finish.
                   $finish = $elem;  # Fake it.
                   $self->__parse_error($file_id,
                                        $filename,
                                        $fileloc, "missing finish");
                }
                push @{ $self->{file_subs}{$file_id} },
                     [
                      $sub,                   # 0
                      $elem->line_number,     # 1
                      $elem->column_number,   # 2
                      $finish->line_number,   # 3
                      $finish->column_number, # 4
                     ];
            } elsif ($elem->isa('PPI::Statement')) {
                # use, no, require
                my $stmt_content = $children[0]->content;
                my $include = $children[2];
                next unless defined $include;
                my $include_content = $include->content;
                my $including_module;
                my $including_file;
                if ($elem->isa('PPI::Statement::Include') &&
                    # use/no/require Module
                    $stmt_content =~ /^(?:use|no|require)$/ &&
                    $include->isa('PPI::Token::Word') &&
                    $include_content !~ /^v?5/) {
                    $including_module = 1;
                } elsif ($stmt_content =~ /^(?:require|do)$/ &&
                         $include->isa('PPI::Token::Quote')) {
                    # require/do "file"
                    $including_file = 1;
                } else {
                    # Not a use/no/require/do, quietly exit stage left.
                    next;
                }
                unless (defined $include) {
                    $self->__parse_error($file_id, $fileloc, "missing include");
                    next;
                }
                my $last = $children[-1];
                my $include_file;
                my $include_string;
                if ($including_module) {
                    $include_string = $include_content;
                    $include_file = $self->__find_module($include_content);
                    $self->{file_modules}{$file_id}{$include_content}++;
                    unless (defined $include_file) {
                        $self->{file_missing_modules}{$file_id}{$include_content}{$fileloc}++;
                        warn "$Sub: warning: Failed to find module '$include_string' in $fileloc\n";
                    }
                } elsif ($including_file) {
                    $include_string = $include->string;
                    $include_file = $self->__find_file($include_string);
                    unless (defined $include_file) {
                        warn "$Sub: warning: Failed to find file '$include_string' in $fileloc\n";
                    }
                }
                if (defined $include_file) {
                    if ($self->{opt}{recurse}) {
                        push @{ $self->{__incs_pending}{$file_id} },
                             [
                              $stmt_content,         # 0
                              $elem->line_number,    # 1
                              $elem->column_number,  # 2
                              $last->line_number,    # 3
                              $last->column_number,  # 4
                              $include_string,       # 5
                              $include_file,         # 6
                              # 7 will be the file_id of include_file
                             ];
                    } else {
                        $self->__assign_file_id($include_file);
                    }
                }
            }
        }
        if ($elem->isa('PPI::Structure')) {
            # { ... }
            unshift @queue, $elem->finish if $elem->finish;
            unshift @queue, @children;
            unshift @queue, $elem->start  if $elem->start;
        } else {
            unshift @queue, @children;
        }
        $prev_elem = $elem;
        $prev_package = $package;
    }
    if (defined $elem) {
        $self->{file_lines}{$file_id} = $elem->line_number;
        $self->__close_package($file_id, $package, $elem);
    } elsif (@{ $doc->{children} }) {
        $self->__parse_error($file_id, $filename,
                             "Undefined token when leaving");
    }

    # Mark the __incs_pending as ready to be recursed into.
    $self->{__incs_flush}{$file_id}++;

    $self->__process_pending_incs($file_id, $process_depth);
}

sub __trash_cache {
    my $self = shift;
    delete $self->{result_cache};
    delete $self->{seen_file};
}

# Parse the given filenames (or if a scalar ref, a string of code,
# in which case filename is assumed to be '-').
sub process {
    my $self = shift;
    $self->__trash_cache;
    my $success = 1;
    for my $arg (@_) {
        my $file;
        my $ref = ref $arg;
        if ($ref eq '') {
            $file = $arg;
        } elsif ($ref eq 'SCALAR') {
            $file = '-';
        } else {
            warn "$Sub: Unexpected argument '$arg' (ref: $ref)\n";
            $success = 0;
            next;
        }
        my $file_id = $self->__process_file($arg, $file, 0);
        unless (defined $file_id) {
            $success = 0;
            next;
        }
        $self->{__process}{ $file_id }++;
    }
    return $success;
}

sub process_files_from_cache {
    my $self = shift;
    my %files;
    $self->find_cache_files(\%files);
    if ($self->{opt}{process_verbose} || $self->{opt}{cache_verbose}) {
        my $cache_directory = $self->{opt}{cache_directory};
        printf("$Sub: found %d cache files from %s\n",
               scalar keys %files, $cache_directory);
    }
    $self->process(sort keys %files);
}

sub process_files_from_system {
    my $self = shift;
    my %files;
    $self->find_system_files(\%files);
    if ($self->{opt}{process_verbose}) {
        my $cache_directory = $self->{opt}{cache_directory};
        printf("$Sub: found %d system files from @INC\n",
               scalar keys %files);
    }
    $self->process(sort keys %files);
}

# Returns the seen filenames.
sub files {
    my $self = shift;
    unless (defined $self->{result_cache}{files}) {
        return unless $self->{file_id};
        $self->{result_cache}{files} = [ sort keys %{ $self->{file_id} } ];
    }
    return @{ $self->{result_cache}{files} };
}

# Computes the total number of lines.
sub total_lines {
    my $self = shift;
    unless (defined $self->{result_cache}{total_lines}) {
        return unless $self->{file_lines};
        use List::Util qw[sum];
        $self->{result_cache}{total_lines} = sum grep { defined } values %{ $self->{file_lines} };
    }
    return $self->{result_cache}{total_lines};
}

# Lines in a file.
sub file_lines {
    my ($self, $file) = @_;
    return $self->{file_lines}{$self->{file_id}{$file}};
}

# Returns the known file ids.
sub __file_ids {
    my $self = shift;
    unless (defined $self->{result_cache}{__file_ids}) {
        return unless $FILE_ID;
        $self->{result_cache}{__file_ids} = [ 0..$FILE_ID-1 ];
    }
    return @{ $self->{result_cache}{__file_ids} };
}

# Returns the reference count of a filename.
sub file_count {
    my ($self, $file) = @_;
    return unless $self->{file_counts};
    return $self->{file_counts}->{$file};
}

# Computes the seen modules.
sub __modules {
    my $self = shift;
    unless (defined $self->{result_cache}{modules}) {
        return unless $self->{file_modules};
        delete $self->{modules};
        for my $f ($self->__file_ids) {
            for my $m (keys %{ $self->{file_modules}{$f} }) {
                $self->{modules}{$m} += $self->{file_modules}{$f}{$m};
            }
        }
        $self->{result_cache}{modules} = [ sort keys %{ $self->{modules} } ];
    }
}

# Returns the seen modules.
sub modules {
    my $self = shift;
    $self->__modules;
    return @{ $self->{result_cache}{modules} };
}

# Computes the missing modules.
sub __missing_modules {
    my $self = shift;
    unless (defined $self->{result_cache}{missing_modules}) {
        $self->{result_cache}{missing_modules} //= [];
        $self->{result_cache}{missing_modules_files} //= {};
        $self->{result_cache}{missing_modules_count} //= {};
        return unless $self->{file_missing_modules};
        delete $self->{missing_modules};
        delete $self->{missing_modules_files};
        delete $self->{missing_modules_lines};
        delete $self->{missing_modules_count};
        for my $f ($self->__file_ids) {
            my $file = $FILE_BY_ID{$f};
            for my $m (keys %{ $self->{file_missing_modules}{$f} }) {
                for my $l (keys %{ $self->{file_missing_modules}{$f}{$m} }) {
                    my $c = $self->{file_missing_modules}{$f}{$m}{$l};
                    $self->{missing_modules_files}{$m}{$file} += $c;
                    $self->{missing_modules_lines}{$m}{$l} += $c;
                    $self->{missing_modules_count}{$m} += $c;
                }
            }
        }
        $self->{result_cache}{missing_modules} =
            [ sort keys %{ $self->{missing_modules_files} } ];
    }
}

# Returns the missing modules.
sub missing_modules {
    my $self = shift;
    $self->__missing_modules;
    return @{ $self->{result_cache}{missing_modules} };
}

# Returns the total reference count of a module name.
sub module_count {
    my ($self, $module) = @_;
    $self->__modules;
    return 0 unless $self->{modules};
    return $self->{modules}->{$module} || 0;
}

# Returns the files referring a missing module.
sub missing_module_files {
    my ($self, $module) = @_;
    $self->__missing_modules;
    return unless $self->{missing_modules_files}{$module};
    return sort keys %{ $self->{missing_modules_files}{$module} };
}

# Returns the lines referring a missing module.
sub missing_module_lines {
    my ($self, $module) = @_;
    $self->__missing_modules;
    return unless $self->{missing_modules_lines}{$module};
    return map  { "$_->[0]:$_->[1]" }
           sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
           map  { /^(.+):(\d+)$/ ? [ $1, $2 ] : [ $_, 0 ] }
           keys %{ $self->{missing_modules_lines}{$module} };
}

# Returns the times a missing module was referred.
sub missing_module_count {
    my ($self, $module) = @_;
    $self->__missing_modules;
    return 0 unless $self->{missing_modules_count}{$module};
    return $self->{missing_modules_count}{$module} || 0;
}

# Computes the parse errors.
sub __parse_errors {
    my $self = shift;
    unless (defined $self->{result_cache}{parse_errors_files}) {
        $self->{result_cache}{parse_errors_files} //= [];
        return unless exists $self->{file_parse_errors};
        delete $self->{parse_errors_files};
        for my $f ($self->__file_ids) {
            for my $l (keys %{ $self->{file_parse_errors}{$f} }) {
                $self->{parse_errors_files}{$FILE_BY_ID{$f}}++;
            }
        }
        $self->{result_cache}{parse_errors_files} =
            [ sort keys %{ $self->{parse_errors_files} } ];
    }
}

# Return the files with parse errors.
sub parse_errors_files {
    my $self = shift;
    $self->__parse_errors;
    return @{ $self->{result_cache}{parse_errors_files} };
}

# Return the parse errors in a file, as a hash of filelocation -> error.
sub file_parse_errors {
    my ($self, $file) = @_;
    $self->__parse_errors;
    return unless exists $self->{file_parse_errors};
    return unless defined $file;
    my $file_id = $self->{file_id}{$file};
    return unless defined $file_id;
    return unless exists $self->{file_parse_errors}{$file_id};
    return %{ $self->{file_parse_errors}{$file_id} };
}

# Generates the subs or packages.
sub __subs_or_packages {
    my ($self, $key, $cache) = @_;
    unless (defined $self->{result_cache}{$cache}) {
        return unless $self->{$key};
        my %uniq;
        for my $f ($self->__file_ids) {
            @uniq{ map { $_->[0] } @{ $self->{$key}{$f} } } = ();
        }
        $self->{result_cache}{$cache} = [ sort keys %uniq ];
    }
    return @{ $self->{result_cache}{$cache} };
}

# Returns the subs.
sub subs {
    my $self = shift;
    return $self->__subs_or_packages(file_subs => 'subs');
}

# Returns the packages.
sub packages {
    my $self = shift;
    return $self->__subs_or_packages(file_packages => 'packages');
}

# Generates the subs' or packages' files.
sub __subs_or_packages_and_files {
    my ($self, $key, $cache) = @_;
    unless (defined $self->{result_cache}{$cache}) {
        return [] unless $self->{$key};
        my @cache;
        for my $f ($self->__file_ids) {
            for my $s (@{ $self->{$key}{$f} }) {
                push @cache,
                     [ $s->[0], $f, @{$s}[1..$#$s] ];
            }
        }
        $self->{result_cache}{$cache} = [
            sort { $a->[0] cmp $b->[0] ||
                   $FILE_BY_ID{$a->[1]} cmp $FILE_BY_ID{$b->[1]} ||
                   $a->[2] <=> $b->[2] ||
                   $a->[3] <=> $b->[3] }
            @cache ];
    }
    return $self->{result_cache}{$cache};
}

# Returns the subs' files (an aref to iterate through).
sub __subs_files_full {
    my $self = shift;
    $self->__subs_or_packages_and_files(file_subs => '__subs_files');
}

# Returns the packages' files (an aref to iterate through).
sub __packages_files_full {
    my $self = shift;
    $self->__subs_or_packages_and_files(file_packages => '__packages_files');
}

# Base class for returning iterator results.
package PPI::Xref::IterResultBase {
    # Result as a string.
    # The desired fields are selected, and concatenated.
    sub string {
        my $self = shift;
        return $self->{cb}->($self->{it});
    }
    # Result as an array.
    sub array {
        my $self = shift;
        return @{ $self->{it} };
    }
}

package PPI::Xref::FileIterResult {
    use parent -norequire, 'PPI::Xref::IterResultBase';
}

package PPI::Xref::FileIterBase {
    # Base class method for stepping through the subs' and packages' files.
    # Converts the file id into filename, and returns iterator result.
    sub next {
        # NOTE: while this is an iterator in the sense of returning the next
        # result, this does not compute the next result because all the results
        # have already been computed when the iterator was constructed.
        my $self = shift;
        if ($self->{ix} < @{$self->{it}}) {
            my @it = @{ $self->{it}->[$self->{ix}++] };
            $it[1] = $FILE_BY_ID{$it[1]};
            return bless { it => \@it, cb => $self->{cb} },
                         'PPI::Xref::FileIterResult'
        }
        return;
    }
}

package PPI::Xref::SubsFilesIter {
    use parent -norequire, 'PPI::Xref::FileIterBase';
}

package PPI::Xref::PackagesFilesIter {
    use parent -norequire, 'PPI::Xref::FileIterBase';
}

# Callback generator for subs' and packages' files.
# Selects the desired fields, and concatenates the fields.
sub __file_iter_callback {
    my $opt = shift;
    sub {
        my $self = shift;
        join($opt->{separator} // "\t",
             @{$self}[0, 1, 2],
             @{$self}[$opt->{column} ?
                      ($opt->{finish} ? (3, 4, 5) : (3)) :
                      ($opt->{finish} ? (4) : ())]
            );
    }
}

# Constructor for iterating through the subs' files.
sub subs_files_iter {
    my ($self, $opt) = @_;
    bless {
        it => $self->__subs_files_full,
        ix => 0,
        cb => __file_iter_callback($opt),
    }, 'PPI::Xref::SubsFilesIter';
}

# Constructor for iterating through the packages' files.
sub packages_files_iter {
    my ($self, $opt) = @_;
    bless {
        it => $self->__packages_files_full,
        ix => 0,
        cb => __file_iter_callback($opt),
    }, 'PPI::Xref::PackagesFilesIter';
}

# Generates all the inclusion files and caches them.
# The inclusion files are the file id, followed all its inclusions.
# Sorting is by filename, line, column, and include_string (e.g. Data::Dumper).
sub __incs_files_full {
    my ($self) = @_;
    unless (defined $self->{result_cache}{__incs_files}) {
        my @cache;
        for my $f ($self->__file_ids) {
            for my $i (@{ $self->{file_incs}{$f} }) {
                push @cache, [ $f,      # 0: fileid1
                               @{$i}[1, # 1: line
                                     7, # 2: fileid2
                                     0, # 3: stmt
                                     5, # 4: include_string
                                     2, # 5: col
                                     3, # 6: line
                                     4, # 7: col
                               ] ],
            }
        }
        $self->{result_cache}{__incs_files} = [
            sort { $FILE_BY_ID{$a->[0]} cmp $FILE_BY_ID{$b->[0]} ||
                   $a->[1] <=> $b->[1] ||  # line
                   $a->[2] <=> $b->[2] ||  # column
                   $a->[5] cmp $b->[5] }   # include_string
            @cache ];
    }
    return $self->{result_cache}{__incs_files};
}

# Callback generator for inclusion files.
# Selects the desired fields, and concatenates the fields with the separator.
sub __incs_files_iter_callback {
    my $opt = shift;
    sub {
        my $self = shift;
        join($opt->{separator} // "\t",
             @{$self}[0..4],
             @{$self}[$opt->{column} ?
                      ($opt->{finish} ? (5, 6, 7) : (5)) :
                      ($opt->{finish} ? (6) : ())],
            );
    }
}

package PPI::Xref::IncsFilesIterResult {
    use parent -norequire, 'PPI::Xref::IterResultBase';
}

package PPI::Xref::IncsFilesIter {
    # Iterator stepper for iterating through the inclusion files.
    # Converts the file ids to filenames, and returns iterator result.
    sub next {
        # NOTE: while this is an iterator in the sense of returning the next
        # result, this does not compute the next result because all the results
        # have already been computed when the iterator was constructed.
        my $self = shift;
        if ($self->{ix} < @{$self->{it}}) {
            my @it = @{ $self->{it}->[$self->{ix}++] };
            $it[0] = $FILE_BY_ID{$it[0]};
            $it[2] = $FILE_BY_ID{$it[2]};
            return bless { it => \@it, cb => $self->{cb} },
                         'PPI::Xref::IncsFilesIterResult'
        }
        return;
    }
}

# Constructor for iterating through the inclusion files.
sub incs_files_iter {
    my ($self, $opt) = @_;
    bless {
        it => $self->__incs_files_full,
        ix => 0,
        cb => __incs_files_iter_callback($opt),
    }, 'PPI::Xref::IncsFilesIter';
}

# Recursive generator for inclusion chains.  If there are inclusions
# from this file, recurse for them; if not, aggregate into the result.
sub __incs_chains_recurse {
    my ($self, $file_id, $path, $seen, $result) = @_;
    my @s =
        exists $self->{file_incs}{$file_id} ?
        @{ $self->{file_incs}{$file_id} } : ();
    $seen->{$file_id}++;
    # print "recurse: $FILE_BY_ID{$file_id} path: [@{[map { $FILE_BY_ID{$_} // $_ } @$path]}] \n";
    my $s = 0;
    for my $i (@s) {
        my ($line, $next_file_id) = ($i->[1], $i->[-1]);
        # print "recurse: $FILE_BY_ID{$file_id}:$line -> $FILE_BY_ID{$next_file_id} path: [@{[map { $FILE_BY_ID{$_} // $_ } @$path]}] seen: [@{[sort map { $FILE_BY_ID{$_} } keys %$seen]}]\n";
        # E.g. Carp uses strict, strict requires Carp.
        unless ($seen->{$next_file_id}++) {
            $self->__incs_chains_recurse($next_file_id, [ @$path, $line, $next_file_id ], $seen, $result);
            $s++;
        }
    }
    if ($s == 0) {  # If this was a leaf (no paths leading out), aggregrate result.
        push @{$result}, [ @$path ];
    }
    delete $seen->{$file_id};
}

sub __incs_deps {
    my ($self) = @_;
    unless (defined $self->{result_cache}{__incs_deps}) {
        my %pred;
        my %succ;
        my %line;
        for my $fi ($self->__file_ids) {
            if (exists $self->{file_incs}{$fi}) {
                for my $g (@{ $self->{file_incs}{$fi} }) {
                    my ($gl, $gi) = @{ $g }[ 1, 7 ];
                    $succ{$fi}{$gi}{$gl}++;
                    $pred{$gi}{$fi}{$gl}++;
                    $line{$fi}{$gl}{$gi}++;
                }
            }
        }
        my %singleton;
        my %leaf;
        my %root;
        my %branch;
        for my $s ($self->__file_ids) {
            my @s = exists $succ{$s} ? keys %{$succ{$s}} : ();
            my @p = exists $pred{$s} ? keys %{$pred{$s}} : ();
            if (@s == 0) {
                if (@p == 0) {
                    $singleton{$s}++;
                } else {
                    $leaf{$s}++;
                }
            } elsif (@p == 0) {
                $root{$s}++;
            } else {
                $branch{$s}++;
            }
        }
        $self->{result_cache}{__incs_deps} = {
            pred => \%pred,
            succ => \%succ,
            line => \%line,
            singleton => \%singleton,
            leaf => \%leaf,
            root => \%root,
            branch => \%branch,
            parent => $self,
        };
    }
    return $self->{result_cache}{__incs_deps};
}

package PPI::Xref::IncsDeps {
    sub files {
        my ($self) = @_;
        return $self->{parent}->files;
    }
    sub __file_id {
        my ($self, $file) = @_;
        return $self->{parent}{file_id}{$file};
    }
    sub __by_file {
        my ($self, $key, $file) = @_;
        my $file_id = $self->__file_id($file);
        return unless defined $file_id && exists $self->{$key}{$file_id};
        return keys %{ $self->{$key}{$file_id} };
    }
    sub __filenames {
        my $self = shift;
        return map { $FILE_BY_ID{$_} } @_;
    }
    sub __predecessors {
        my ($self, $file) = @_;
        return _$self->__by_file(pred => $file);
    }
    sub __successors {
        my ($self, $file) = @_;
        return $self->__by_file(succ => $file);
    }
    sub predecessors {
        my ($self, $file) = @_;
        return $self->__filenames(_$self->__predecessors($file));
    }
    sub successors {
        my ($self, $file) = @_;
        return $self->__filenames($self->__successors($file));
    }
    sub __files {
        my ($self, $key) = @_;
        return exists $self->{$key} ?
            map { $FILE_BY_ID{$_} } keys %{ $self->{$key} } : ();
    }
    sub __roots {
        my ($self) = @_;
        return exists $self->{root} ? keys %{ $self->{root} } : ();
    }
    sub __singletons {
        my ($self) = @_;
        return exists $self->{singleton} ? keys %{ $self->{singleton} } : ();
    }
    sub roots {
        my ($self) = @_;
        return $self->__files('root');
    }
    sub leaves {
        my ($self) = @_;
        return $self->__files('leaf');
    }
    sub singletons {
        my ($self) = @_;
        return $self->__files('singleton');
    }
    sub branches {
        my ($self) = @_;
        return $self->__files('branch');
    }
    sub __file_kind {
        my ($self, $file_id) = @_;
        return unless defined $file_id;
        return 'branch'    if exists $self->{branch}   {$file_id};
        return 'leaf'      if exists $self->{leaf}     {$file_id};
        return 'root'      if exists $self->{root}     {$file_id};
        return 'singleton' if exists $self->{singleton}{$file_id};
        return;
    }
    sub file_kind {
        my ($self, $file) = @_;
        return $self->__file_kind($self->__file_id($file));
    }
}

sub incs_deps {
    my ($self) = @_;
    bless $self->__incs_deps, 'PPI::Xref::IncsDeps';
}

sub __incs_chains_iter {
    my ($self, $opt) = @_;
    my %iter;
    my $deps = $self->incs_deps;
    if (defined $deps) {
        $iter{next} = sub {
            my ($iterself) = @_;
            until ($iterself->{done}) {
                unless (defined $iterself->{path} && @{ $iterself->{path} }) {
                    unless (defined $iterself->{roots}) {
                        my @roots = (
                            $deps->__roots,
                            $deps->__singletons,
                            );
                        my %roots;
                        @roots{@roots} = ();
                        if (exists $self->{__process}) {
                            for my $id (keys %{ $self->{__process} }) {
                                push @roots, $id unless exists $roots{$id};
                            }
                        }
                        $iterself->{roots} = \@roots;
                    }
                    my $root = shift @{ $iterself->{roots} };
                    unless (defined $root) {
                        $iterself->{done}++;
                        return;
                    }
                    $iterself->{path} = [ $root ];
                    # E.g. Carp uses strict, strict requires Carp, and also
                    # the dependency trees are very probably not clean DAGs.
                    $iterself->{seen} = { $root => { 0 => 1 } };
                };
                while (@{ $iterself->{path} }) {
                    my $curr = $iterself->{path}[-1];
                    my $pushed = 0;
                  SUCC: {
                      if (exists $deps->{line}{$curr}) {
                          for my $line (sort { $a <=> $b }
                                        keys %{ $deps->{line}{$curr} }) {
                              for my $succ (sort { $a cmp $b }
                                            keys %{ $deps->{line}{$curr}{$line} }) {
                                  unless ($iterself->{seen}{$succ}{$line}++) {
                                      push @{ $iterself->{path} }, $line, $succ;
                                      $pushed++;
                                      last SUCC;
                                  }
                              }
                          }
                      }
                    }
                    unless ($pushed) {
                        if (my @path = @{ $iterself->{path} }) {
                            @path = reverse @path if $opt->{reverse_chains};
                            if (@path > 1) {
                                splice @{ $iterself->{path} }, -2;  # Double-pop.
                                if ($self->{lastpush}) {
                                    $self->{lastpush} = $pushed;
                                    return @path;
                                }
                            } else {
                                $iterself->{path} = [];
                                my $kind = $deps->__file_kind($curr);
                                if (defined $kind && $kind eq 'singleton') {
                                    return @path;
                                }
                            }
                        }
                    }
                    $self->{lastpush} = $pushed;
                }  # while
            }
        };
    }
    return \%iter;
}

# Callback generator for inclusion chains.
# Simply concatenates the fields with the separator.
sub __incs_chains_iter_callback {
    my $opt = shift;
    sub {
        my $self = shift;
        join($opt->{separator} // "\t", @{$self} );
    }
}

package PPI::Xref::IncsChainsIterResult {
    use parent -norequire, 'PPI::Xref::IterResultBase';
}

package PPI::Xref::IncsChainsIter {
    # Iterator stepper for iterating through the inclusion chains.
    # Converts the file ids to filenames, and returns iterator result.
    sub next {
        my $self = shift;
        if (my @it = $self->{it}{next}->($self)) {
            for (my $i = 0; $i < @it; $i += 2) {
                $it[$i] = $FILE_BY_ID{$it[$i]};
            }
            return bless { it => \@it, cb => $self->{cb} },
                         'PPI::Xref::IncsChainsIterResult';
        }
        return;
    }
}

# Constructor for iterating through the inclusion chains.
sub incs_chains_iter {
    my ($self, $opt) = @_;
    bless {
        it => $self->__incs_chains_iter($opt),
        ix => 0,
        cb => __incs_chains_iter_callback($opt),
    }, 'PPI::Xref::IncsChainsIter';
}

sub looks_like_cache_file {
    my ($self, $file) = @_;

    my $cache_directory = $self->{opt}{cache_directory};
    return unless defined $cache_directory;

    return 0 if $file =~ m{\.\.};

    return $file =~ m{^\Q$cache_directory\E[/\\].+\Q$CACHE_EXT\E$};
}

sub cache_delete {
    my $self = shift;
    my $cache_directory = $self->{opt}{cache_directory};
    unless (defined $cache_directory) {
        warn "$Sub: cache_directory undefined\n";
        return;
    }
    my $delete_count = 0;
    for my $file (@_) {
        if (!File::Spec->file_name_is_absolute($file) ||
            $file =~ m{\.\.} ||
            ($file !~ m{[._]p[ml](?:\Q$CACHE_EXT\E)?$} &&
             $file !~ m{.p[ml]$})) {
            # Paranoia check one.
            warn "$Sub: Skipping unexpected file: '$file'\n";
            next;
        }
        my $cache_file =
            $file =~ /\Q$CACHE_EXT\E$/ ?
            $file : $self->__cache_filename($file);
        # Paranoia check two.  Both paranoia checks are needed.
        unless ($self->looks_like_cache_file($cache_file)) {
            warn "$Sub: Skipping unexpected cache file: '$cache_file'\n";
            next;
        }
        if ($self->{opt}{cache_verbose}) {
            print "cache_delete: deleting $cache_file\n";
        }
        if (unlink $cache_file) {
            $delete_count++;
            $self->{__cachedeletes}++;
        }
    }
    return $delete_count;
}

sub __unparse_cache_filename {
    my ($self, $cache_filename) = @_;

    my $cache_directory = $self->{opt}{cache_directory};
    return unless defined $cache_directory;

    return unless $cache_filename =~ s{\Q$CACHE_EXT\E$}{};

    my $cache_prefix_length = $self->{__cache_prefix_length};
    return unless length($cache_filename) > $cache_prefix_length;

    my $prefix = substr($cache_filename, 0, $cache_prefix_length);
    return unless $prefix =~ m{^\Q$cache_directory\E(?:/|\\)$};

    my $path = substr($cache_filename, $cache_prefix_length - 1);

    $path =~ s{_(p[ml])$}{\.$1};  # _pm -> .pm, _pl -> .pl

    if ($^O eq 'MSWin32') {
      # \c\a\b -> c:/a/b
      $path =~ s{\\}{/}g;
      if ($path =~ m{^/([A-Z])(/.+)}) {
        my $volpath = "$1:$2";
        if (-f $volpath) {
          $path = $volpath;
        }
      }
    }

    return $path;
}

# Given an xref, find all the cache files under its cache directory,
# and add their filenames to href.
sub find_cache_files {
    my ($self, $files) = @_;

    my $cache_directory = $self->{opt}{cache_directory};
    unless (defined $cache_directory) {
        warn "$Sub: cache_directory undefined\n";
        return;
    }

    use File::Find qw[find];

    find(
        sub {
            if (/\.p[ml]\Q$CACHE_EXT\E$/) {
                my $name = $self->__unparse_cache_filename($File::Find::name);
                $files->{$name} = $File::Find::name;
            }
        },
        $cache_directory);
}

# Given an xref, find all the pm files under its INC,
# and add their filenames to href.
sub find_system_files {
    my ($self, $files) = @_;

    use File::Find qw[find];

    for my $d (@{ $self->INC }) {
        find(
            sub {
                if (/\.p[ml]$/) {
                    $files->{$File::Find::name} = $File::Find::name;
                }
            },
            $d);
    }
}

1;
__DATA__
=pod

=head1 NAME

PPI::Xref - generate cross-references for Perl code

=head1 DESCRIPTION

    use PPI::Xref;

    my $xref = PPI::Xref->new();  # Constructor.

PPI::Xref can be used to process files of Perl code or Perl code as a
string, and then generate cross-references of its contents.  The code
is never executed, only parsed as a document tree.

B<NOTE:> the cross-reference is not a call graph.  Instead, it is a
statically generated graph of I<file inclusions> and named F<sub> definitions.

B<NOTE:> all the use/no/require/do are followed, which means that for
example optional or platform specific modules will fail to be found.
This is expected and fine.

=head2 Options

    my $xref = PPI::Xref->new($opt);

The $opt is a href of options.  Possible options:

=over 4

=item recurse

Boolean, whether to recurse or not, default yes.

B<NOTE:> even with false C<recurse> the files referred to at the first
level (for example, C<X.pm> for C<use X>) will be looked up.  But no
further descending into those files will happen, so subs from those
files will not be found.

=item verbose

Boolean, if true, progress messages are shown during the processing.

=item INC

An aref of directories, default [ @INC ].  You can retrieve the
aref (with non-accessible non-directories removed) as $xref->INC.

=item cache_directory

String, a directory name.  For paranoia, the directory must exist.  If
defined, use for the PPI processing results of source files, including
the (SHA-1) hash checksum of the file, and the results derived from
PPI parsing.

=back

=head2 Processing

Process one or more files.  They are looked for in the @INC,
or in the INC specified via the constructor.

    $xref->process($filename, ...);

Process string of Perl code, pass it in as scalar ref.
This will show up as filename '-'.

    $xref->process(\$string);

=head2 Queries

Once you have processed all the inputs you can query the object for
various results.  More complex results need to queried using iterators.

=head3 files

Fully resolved filenames.

    $xref->files

=head3 subs

Fully qualified subroutine names.

    $xref->subs

=head3 packages

Package names in package statements.

    $xref->packages

=head3 modules

Module names in use/no/require.

    $xref->modules

=head3 file_count

The total number of times the file is referred to by F<file inclusion>.

    $xref->file_count($file)

=head3 module_count

The total number of times the module is referred to by use/no/require.

    $xref->module_count($module)

=head3 file_lines

The number of lines in the file.

    $xref->file_lines($file)

=head3 total_lines

The total number of lines in all the seen files.

    $xref->total_lines()

=head3 subs_files_iter

    my $sfi = $xref->subs_files_iter;
    while (my $sf = $sfi->next) {
      my ($subname, $filename, $linenumber) = $sf->array;
      my $sfs = $sf->string;  # Single string concatenating the columns.
    }

B<NOTE>: the subnames are not necessarily unique, for multiple reasons:

=over 4

=item BEGIN, END, and similar, can occur multiple times

=item simply the same sub defined in multiple files

=back

The iter constructor can also take an options href:

=over 4

=item separator

String for joining, for the string() method.

=item column

Boolean, whether the also column numbers should be returned.

=item finish

Boolean, should also the end line/column of the sub be returned.

=back

=head3 packages_files_iter

Like subs_files_iter, but for packages.

    my $pfi = $xref->packages_files_iter;

Options as with L</subs_files_iter>.

B<NOTE 1>: since packages are lexically scoped, and since a single
file can declare multiple packages, and since any file may declare any
package, the same package name may be listed multiple times.

B<NOTE 2>: the results of the C<finish> option, and specially if
combined with the C<column> option, are sometimes slightly debatable:
in which package do the whitespace tokens belong, for example?

=head3 incs_files_iter

I<File inclusion>: any of C<use> / C<no> / C<require> / C<do> (file).

    my $ifi = $xref->incs_files_iter;
    while (my $if = $ifi->next) {
      # The $first_file line $linenumber includes the $second_file.
      my (
           $first_file,
           $linenumber,
           $second_file,    # full path filename
           $stmt_content,   # string: use/no/require/do
           $include_string, # module name (use/no/require) or filename (require/do)
           ...
         ) = $if->array;
      my $ifs = $if->string;  # Single string concatenating the columns.
    }

Options as with L</subs_files_iter>.  Depending on the C<column> and C<finish>
options, the ... can have none to three elements (default none).

=head3 incs_chains_iter

I<Inclusion chains>: starting from all the root files, singleton files
(if any, see L</incs_deps>), and then files given to process(), return
the full inclusion chains of files.  What this basically means is dependencies.

B<NOTE 1: this does not return all the possible paths>, since that would
be ill-defined for inclusion loops, and diamond patterns.  What this
returns is (starting from the roots and singletons), all the possible
paths that do not cause loops, or in general visiting already seen
files (counting from the current root).  Another way of looking at the
returned results is that if they would be overlaid, they would form a
DAG (directed acyclic graph).

B<NOTE 2: all the possible paths does include multiple inclusions>.
This means that if both the lines F<A.pm:X> and F<A.pm:Y> include F<B.pm>,
both paths (the path through X, and the path through Y) are returned.

B<NOTE 3: there are MANY paths even for the simplest code.>

    my $ici = $xref->incs_chains_iter;
    while (my $ic = $ici->next) {
      # The @ic is either of one element (a file that includes nothing)
      # or 3, 5, 7, ... elements (you can think of this as 2k + 1 where
      # k = 0, 1, 2...)
      # @ic[0, 2, 4, ...] are filenames.
      # @ic[1, 3, 5, ...] are linenumbers.
      my @ic = $ic->array;
      my $ics = $ic->string;  # Single string concatenating the columns.
    }

You can specify C<separator> in the options for the iterator constructor.
(No C<column> or finish options available, for simplicity.)  You can also
specify a boolean C<reverse_chains> option to generate reverse dependencies.

=head3 incs_deps

Computes the B<depth-one> dependency tree of all the seen files.

    my $id = $xref->incs_deps;

    $id->files()               # All the files.
    $id->successors($file)     # The files included.
    $id->predecessors($file)   # The files including.
    $id->roots()               # File nobody is including.
    $id->leaves()              # Files everybody is just including.
    $id->branches()            # Both included and including.
    $id->singletons()          # Neither included nor including.
    $id->file_kind($file)      # 'root', 'leaf', 'branch', 'singleton', or C<undef>.

Note that the 'root', 'leaf', and 'branch' are relative terms: it all
depends on which node you start from.

=head3 docs_created

How many PPI documents have been created.  If cached results are being
used, less documents need be created.

=head3 cache_reads

How many PPI processing results have been read from the cache results.

=head3 cache_writes

How many PPI processing results have been written to the cache results.

=head2 cache_delete

For cache maintenance you may want to delete cache files of removed
source files.  Detection of removed source files is outside the scope
of PPI::Xref (either or both of version control system querying and
file system traversal are likely), but if you know the files, you
can use

  $xref->cache_delete($file, ...)

The specified files have to be either original fully resolved filenames,
(not the INC-relative ones), or the fully resolved cache filenames.

Deletions happen quietly: a missing cache file causes no warning.

Returns the number of successful deletions.

=head3 missing_modules

  @modules = $xref->missing_modules()

Modules that were called for via use/no/require/do but which could
not be found in C<%INC>.

Common reasons include:

=over 8

=item *

Modules that are conditionally invoked, for example based on the operating
system, or configuration options.

=item *

Modules that are invoked based on a runtime value.  PPI does not do runtime.

=back

=head3 missing_module_count

  $count = $xref->missing_module_count($modulename)

Given a name of a missing module, how many times it was referred.

=head3 missing_module_files

  @files = $xref->missing_module_files($modulename)

Given a name of a missing module, returns the files that referred it.

=head3 missing_module_lines

  @lines = $xref->missing_module_lines($modulename)

Given a name of a missing module, returns the lines that referred it.

=head3 parse_errors_files

  @files = $xref->parse_errors_files()

Files that had parsing errors, which PPI could not handle.

F<Document incomplete> is the most common parsing error.
That means that after parsing the file, PPI was left with
unbalanced state, like for example opened but not closed
brace.  This may have been caused by some earlier parsing
issue.

=head3 file_parse_errors

  $xref->file_parse_errors($filename)

Given a filename, return a hash of its parse errors.  The keys are the
error locations (which can be the whole file), the values are the
error details (which can be just "Document incomplete" in the case
of the whole file).

=head1 PREREQUISITES

perl 5.14, L<https://search.cpan.org/perldoc?PPI>, L<https://search.cpan.org/perldoc?Sereal>

=cut
