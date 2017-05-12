package PAR::Dist::FromCPAN;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.11';

use CPAN;
use PAR::Dist;
use File::Copy;
use Cwd qw/cwd abs_path/;
use File::Spec;
use File::Path;
use Module::CoreList;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
    cpan_to_par
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    cpan_to_par
);


our $VERBOSE = 0;


sub _verbose {
    $VERBOSE = shift if (@_);
    return $VERBOSE
}

sub _diag {
    my $msg = shift;
    return unless _verbose();
    print $msg ."\n"; 
}

sub cpan_to_par {
    die "Uneven number of arguments to 'cpan_to_par'." if @_ % 2;
    my %args = @_;
 
    _verbose($args{'verbose'});

    if (not defined $args{pattern}) {
        die "You need to specify a module pattern.";
    }
    my $pattern = $args{pattern};
    my $skip_ary = $args{skip} || [];
    my $target_perl = exists($args{perl_version}) ? ($args{perl_version}||0) : $^V;

    my $outdir = abs_path(defined($args{out}) ? $args{out} : '.');
    die "Output path not a directory." if not -d $outdir;

    _diag "Expanding module pattern.";

    my @modules_queue = grep {
        _skip_this($skip_ary, $_->id) ? () : $_
    } CPAN::Shell->expand('Module', $pattern);
    
    my %seen;
    my %seen_multiple_times;
    my @failed;

    my @par_files;
    
    while (my $mod = shift @modules_queue) {

        my $file = $mod->cpan_file();
        if ($seen{$file}) {
            _diag "Skipping previously processed module:\n".$mod->as_glimpse();

            next;
        }
        $seen{$file}++;
        

        my $first_in = Module::CoreList->first_release( $mod->id );
        if ( defined $first_in and $first_in <= $target_perl ) {
            print "Skipping ".$mod->id.". It's been core since $first_in\n";
            next;
        }

        my $distribution = $mod->distribution;
        if (not defined $distribution) {
            warn "Could not get distribution object for module '" . $mod->id . "'! Skipping!";
            next;
        }
        if ( $distribution->isa_perl ) {
            print "Skipping ".$mod->id.". It's only in the core. OOPS\n";
            next;
        }

        _diag "Processing next module:\n".$mod->as_glimpse();

        # This branch isn't entered because $mod->make() doesn't
        # indicate an error if it occurred...
        if (not $mod->make() and 0) {
            print "Something went wrong making the following module:\n"
              . $mod->as_glimpse()
              . "\nWe will try to continue. A summary of all failed modules "
              . "will be given\nat the end of the script execution in order "
              . "of appearance.\n";
            push @failed, $mod;
        }

        # recursive dependency solving?
        if ($args{follow}) {
            _diag "Checking dependencies.";
            my $dist = $mod->distribution;
            my $pre_req = $dist->prereq_pm;

            if ($pre_req) {
                my @modules =
                    grep {
                        _skip_this($skip_ary, $_->id) ? () : $_
                    }
                    map {CPAN::Shell->expand('Module', $_)}
                    grep { $_ !~ /^(?:build_)?requires$/ }
                    # this is a hack, but some users seem to require "requires"
                    # and "build_requires" whereas I only see modules in $pre_req
                    # itself... --Steffen
                    keys %{$pre_req->{requires} || {}},
                    keys %{$pre_req},
                    keys %{$pre_req->{build_requires} || {}};
                my %this_seen;
                @modules =
                    grep {
                        $seen{$_->cpan_file}
                        || $this_seen{$_->cpan_file}++ ? 0 : 1
                    }
                    @modules;
                _diag "Recursively adding dependencies for ".$mod->id.": \n"
                  . join("\n", map {$_->cpan_file} @modules) . "\n";
                if (@modules) {
                    # first we handle the dependencies,
                    # then revisit the module, then process the
                    # rest of the queue
                    @modules_queue = (@modules, $mod, @modules_queue);
                    # Email::MIME requires Email::Simple and
                    # Email::Simple require Email::MIME. WTF?
                    if ($seen_multiple_times{$file}) {
                        print "I've processed file '$file' multiple times now.\n"
                            . "I will skip it because it seems to have circular dependencies!\n";
                    }
                    else {
                        delete $seen{$file};
                        $seen_multiple_times{$file}++;
                    }
                    next;
                }
            } 
            _diag "Finished resolving dependencies for ".$mod->id;

        }

        # Run tests?
        if ($args{test}) {
            _diag "Running tests.";
            $mod->test();
        }

        _diag "Building PAR ".$mod->id;
        # create PAR distro
        my $dir = $mod->distribution->dir;
        _diag "Module was built in '$dir'.";

        chdir($dir);
        my $par_file;

        # The name of the .par being generated will contain the platform name and
        # perl version. If the user requested an auto-detection, we potentially
        # override this with a platform agnostic suffix. Read the PAR::Repository
        # documentation for an explanation of its meaning.
        my $is_platform_agnostic = $args{auto_detect_pure_perl} && _is_pure_perl($dir);
        _diag "Distribution seems to be pure-Perl. Building platform agnostic PAR distribution." if $is_platform_agnostic;
        eval {
            $par_file = ($is_platform_agnostic
              ? blib_to_par(suffix => "any_arch-any_version.par")
              : blib_to_par()
            );
        } or die "Failed to build PAR distribution $@";
        _diag "Built PAR ".$mod->id." in $par_file";
        die "Could not find PAR distribution file '$par_file'."
          if not -f $par_file;

        _diag "Generated PAR distribution as file '$par_file'";
        _diag "Moving distribution file to output directory '$outdir'.";

        unless(File::Copy::move($par_file, $outdir)) {
            die "Could not move file '$par_file' to directory "
              . "'$outdir'. Reason: $!";
        }
        $par_file = File::Spec->catfile($outdir, $par_file);
        if (-f $par_file) {
            push @par_files, $par_file;
        }
    }

    if (@failed) {
        print "There were modules that failed to build. "
          . "These are in order of appearance:\n";
        foreach (@failed) {
            print $_->as_glimpse()."\n";
        }
    }

    # Merge deps
    if ($args{merge}) {
        _diag "Merging PAR distributions into one:\n". join(', ', @par_files);
        @par_files = reverse(@par_files); # we resolve dependencies _first.
        merge_par( @par_files );
        foreach my $file (@par_files[1..@par_files-1]) {
            File::Path::rmtree($file);
        }
        @par_files = ($par_files[0]);
    }

    # strip docs
    if ($args{strip_docs}) {
        _diag "Removing documentation from the PAR distribution(s).";
        remove_man($_) for @par_files;
    }
    
    return(1);
}

sub _skip_this {
    my $ary = shift;
    my $string = shift;
    study($string) if @$ary > 2;
#   print $string.":\n";
    for (@$ary) {
#       print "--> $_\n";
#       warn("MATCHES: $string"), sleep(5), return(1) if $string =~ /$_/;
        return(1) if $string =~ /$_/;
    }
    return 0;
}

sub _is_pure_perl {
  my $path = shift;
  my $olddir = Cwd::cwd();
  chdir($path);

  _diag "Checking whether the distribution unpacked in directory '$path' is pure-Perl.";

  my $xs_files = qr/(?i:\.(?:swg|xs|[hic])$)/;
  # if we can, read manifest to check for telling file names
  if (-f 'MANIFEST') {
    open my $fh, '<', "MANIFEST" or die "Could not open file MANIFEST for reading: $!";
    while (defined($_=<$fh>)) {
      chomp;
      if ($_ =~ $xs_files) {
        _diag "MANIFEST contains the line '$_' which makes me deem the distribution platform-dependent.";
        chdir($olddir);
        return 0;
      }
    }
  }

  # walk the tree, check for telling file names,
  # grep for Inline::C
  my $has_xs = 0;
  require File::Find;
  File::Find::find(
    sub {
      return if $has_xs; # short-circuit
      my $file = $_;
      if ($file =~ $xs_files) {
        _diag "Directory contains file '$file' which probably makes the distribution platform-dependent.";
        $has_xs = 1;
        return;
      }
      open my $fh, '<', $file
        or die "Could not open file '$file' for reading while scanning for XS: $!";
      while (defined($_=<$fh>)) {
        if (/Inline(?:X::XS|(?:::|\s+)C)/) {
          _diag "File '$file' contains mention of Inline::C => distribution is platform-dependent.";
          $has_xs = 1;
          close($fh);
          return;
        }
      }
      close $fh;
      return;
    }, '.'
  );

  chdir($olddir);
  return !$has_xs;
}

1;
__END__

=head1 NAME

PAR::Dist::FromCPAN - Create PAR distributions from CPAN

=head1 SYNOPSIS

  use PAR::Dist::FromCPAN;
  
  # Creates a .par distribution of the Math::Symbolic module in the
  # current directory.
  cpan_to_par(pattern => '^Math::Symbolic$');
  
  # The same, but also create .par distributions for Math::Symbolic's
  # dependencies and run all tests.
  cpan_to_par(pattern => '^Math::Symbolic$', follow => 1, test => 1);
  
  # Create distributions for all modules below the 'Math::Symbolic'
  # namespace in the 'par-dist/' subdirectory and be verbose about it.
  cpan_to_par(
    pattern => '^Math::Symbolic',
    out     => 'par-dist/',
    verbose => 1,
  );

=head1 DESCRIPTION

This module creates PAR distributions from any number of modules
from CPAN. It exports the cpan_to_par subroutine for this task.

=head2 EXPORT

By default, the C<cpan_to_par> subroutine is exported to the callers
namespace.

=head1 SUBROUTINES

This is a list of all public subroutines in the module.

=head2 cpan_to_par

The only mandatory parameter is a pattern matching the
modules you wish to create PAR distributions from. This works the
same way as, for example C<cpan install MODULEPATTERN>.

Arguments:

  pattern    => 'patternstring'
  out        => 'directory'  (write distribution files to this directory)
  verbose    => 1/0 (verbose mode on/off)
  test       => 1/0 (run module tests on/off)
  follow     => 1/0 (also create distributions for dependencies on/off)
  merge      => 1/0 (merge everything into one .par archive)
  strip_docs => 1/0 (strip all man* and html documentation)
  skip       => \@ary (skip all modules that match any of the regular
                       expressions in @ary)
  auto_detect_pure_perl => 1/0 (Flags the PAR distribution platform and
                                perl version agnostic if it is deemed
                                pure-perl.)
  perl_version => Defaults to your version of Perl. Used to determine
                  which modules are core perl and thus will be skipped.
                  Set this to 0 to package all core modules as well.

=head1 SEE ALSO

The L<PAR::Dist> module is used to create .par distributions from an
unpacked CPAN distribution. The L<CPAN> module is used to fetch the
distributions from the CPAN.

PAR has a mailing list, <par@perl.org>, that you can write to; send an empty mail to <par-subscribe@perl.org> to join the list and participate in the discussion.

Please send bug reports to <bug-par-dist-fromcpan@rt.cpan.org>.

The official PAR website may be of help, too: http://par.perl.org

=head1 AUTHOR

Steffen Mueller, E<lt>smueller at cpan dot orgE<gt>

Jesse Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
