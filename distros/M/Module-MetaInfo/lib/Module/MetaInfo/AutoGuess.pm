package Module::MetaInfo::AutoGuess;
$VERSION = "0.01";
use warnings;
use strict;
use Carp;
use Cwd;
use Symbol;
use File::Find;
use Module::MetaInfo::_Extractor;

use vars qw(@ISA);

@ISA= qw(Module::MetaInfo::_Extractor);

=head1 NAME

Module::MetaInfo::AutoGuess - Guess meta information from perl modules

=head1 USAGE

  use Module::MetaInfo::AutoGuess;
  $mod=new Module::MetaInfo::AutoGuess(perl-module-file.tar.gz);
  $desc=$mod->description();

=head1 DESCRIPTION

This module provides functions for guessing meta information from old
perl modules which have no explicit meta information storage.  The aim
is to provide a transition mechnism through which meta information can
be supported for the majority of perl modules without any extra work
from the module maintainers.

=head1 FUNCTIONS

The meta information which should be generated can be worked out from
the needs of packaging systems such as RPM (RedHat Package Manager:
for RedHat Linux and related Linux distributions), DPKG (Debian
Packager - for Debian GNU/Linux).

=head2 description

This function tries to get a description for the module.  It does this
by searching for files which might have description information then
looking in each one in order (from the most likely to the least -
heuristic guessing) until it finds something which seems to be a
reasonable description.

The description returned should be treated as plain text.  In the
current version however, it may contain unconverted POD directives.
In future these will probably be converted to text.  Possibly some
options should be given about the kind of text to be produced?

=head2 docs

This function returns an array (or reference to an array in a scalar
context) which contains all of the files in the perl module which are
thought to be documentation.

=head1 UNIMPLEMENTED FUNCTIONS

Currently there are no dependency related functions (requires /
provides / suggests).  The first two of these can be taken from
programs included in RPM > 3.0.4 if they are needed.  Please indicate
that you need this to the author.  There isn't a function to return a
module summary.  This would be a one line summary of the function.
Probably best would be to take this from the CPAN modules.txt file.  

=cut

# sub ProcessFileNames
# looks through a list of candidate files names and orders them
# according to desirability then cuts off those that look likely
# to do more harm than good.

# N.B. function call to here is done a bit wierdly...

sub _process_file_names {
    my ($self, $doclist) = @_;
    die "function miscall" unless (ref $self && (ref $doclist eq "ARRAY"));

    print STDERR "Sorting different perl file possibilities\n"
	if ${$self->{_verbose}};

    local $::simplename=$self->{package_name};
    local ($::A, $::B);
    $::simplename =~ s,[-/ ],_,g;
    $::simplename =~ tr/[A-Z]/[a-z]/;

#Ordering Heuristic
#
#best: the description in the module named the same as the package
#
#next: documentation files
#
#next: files named as package
#finally: prefer .pod to .pm to .pl
#
#N.B. sort high to low not low to high

    my @sort_list = sort {
	local $::res=0;
	$::A = $a;
	$::B = $b;
	$::A =~ s,[-/ ],_,g;
	$::A =~ tr/[A-Z]/[a-z]/;
	$::B =~ s,[-/ ],_,g;
	$::B =~ tr/[A-Z]/[a-z]/;

	#bundles seem a bad place to look from our limited experience
	#this might be better as an exception on the next rule??
	return $::res
	    if ( $::res = - (($::B =~ m/(^|_)bundle_/ )
			     <=> ($::A =~ m/(^|_)bundle_/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/$::simplename.(pm|pod|pod)/ )
			   <=> ($::A =~ m/$::simplename.(pm|pod|pod)/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/^readme/ )
			   <=> ($::A =~ m/^readme/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/.pod$/ )
			   <=> ($::A =~ m/.pod$/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/.pm$/ )
			   <=> ($::A =~ m/.pm$/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/.pl$/ )
			   <=> ($::A =~ m/.pl$/ )) ) ;
	return $::res
	    if ( $::res = (($::B =~ m/$::simplename/ )
			   <=> ($::A =~ m/$::simplename/ )) ) ;
	return length $::B <=> length $::A;
    } @$doclist;

    print STDERR "Checking which fies could really be used\n"
	if ${$self->{_verbose}};
    my $useful=0; #assume first always good
  CASE: {
      $#sort_list == 1 && do {
	  $useful=1;
	  last CASE;
      };
      while (1) {
	  $useful==$#sort_list and last CASE;
	  #non perl files in the list must be there for some reason
	  ($sort_list[$useful+1] =~ m/\.p(od|m|l)$/) or do {$useful++; next};
	  my $cmp_name=$sort_list[$useful+1];
	  $cmp_name =~ s,[-/ ],_,g;
	  $cmp_name =~ tr/[A-Z]/[a-z]/;
	  #perl files should look something like the package name???
	  ($cmp_name =~ m/$::simplename/) && do {$useful++; next};
	   last CASE;
      }
  }
    $#sort_list = $useful;

    print STDERR "Description file list is as follows:\n  " ,
        join ("\n  ", @sort_list), "\n" if ${$self->{_verbose}};

    #FIXME: ref return would be more efficient
    return \@sort_list;
}


# sub _check_perl_prog_for_desc

# given a documentation file, see if we can extract a description from it

sub _check_doc_file_for_desc {
    my $self=shift;
    my $filename=shift;
    my $fh = Symbol::gensym();
    print STDERR "Try to use $filename as description\n"
      if ${$self->{_verbose}};
    open($fh, "<$filename") || die "Failed to open $filename: $!";
    my $desc;
    my $linecount=1;
  LINE: while ( my $line=<$fh> ) {
      $desc .= $line;
      $linecount++;
      $linecount > 30 && last LINE;
    }
    close($fh) or die "Failed to close $filename $!";
    #FIXME: quality check
    $linecount > 2 or return undef;
    return $desc if ( $desc );
}


# sub _check_perl_prog_for_desc

# given a valid perl program see if there is a valid description in it.

sub _check_perl_prog_for_desc {
    my $self=shift;
    my $filename=shift;
    my $desc="";
    my $fh = Symbol::gensym();
    print STDERR "Try to use $filename as description\n"
      if ${$self->{_verbose}};
    open($fh, $filename) || die "Failed to open $filename: $!";;

    my $linecount=1;
  LINE: while (my $line=<$fh>){
      ($line =~ m/^=head1[\t ]+DESCRIPTION/) and do {
	  while ( $line=<$fh> ) {
	      ($line =~ m/^=(head1)|(cut)/) and last LINE;
	      $desc .= $line;
	      $linecount++;
	      $linecount > 30 && last LINE;
	  }
      };
      #tests to see if the descripiton is good enough
      #FIXME: mentions package name?
  }
    close($fh) or die "Failed to close $filename $!";
    ( $desc =~ m/(....\n.*){3}/m ) and do {
#Often descriptions don't say the name of the module and
#furthermore they always assume that we know they are a perl
#module so put in a little header.
	$desc =~ s/^\s*\n//;
	$desc="This package contains the perl module " .
	    $self->{package_name} . ".\n\n" . $desc;
	print STDERR "Found description in $filename\n" if ${$self->{_verbose}};
	return $desc;
    };
    print STDERR "No description found in $filename\n" if ${$self->{_verbose}};
    return undef;
}



#=head1 $self->_check_files_for_desc()
#
#this function looks at a files in a list and for each in order identifies
#if it has content that could be used as a module description.
#
#=cut

sub _check_files_for_desc {

    my $doc_list=&_process_file_names;

    my $self = shift;
    my $desc;

  FILE: foreach my $filename ( @$doc_list ){
      -e $filename or 
	  do {print STDERR "no $filename file\n" if ${$self->{'_verbose'}};
	      next FILE};
      $filename =~ m/\.p(od|m|l)$/ && do  {
	  $desc=$self->_check_perl_prog_for_desc($filename);
	  $desc && last FILE;
	  next FILE;
      };
      $desc=$self->_check_doc_file_for_desc($filename);
      last FILE if $desc;
  }
    return $desc;
}

=head2 description

This function finds and returns a description of the perl module.

In the current implementation we use a set of wierd heuristics to
guess what is the best description available.

When creating an rpm, for example, it's a good idea to proceed the
description with something to the effect of:

  this rpm contains the perl module XXX

where XXX is the name you are using for the perl module.

=cut

sub description {
  my $self=shift;
  croak "$self must be a reference" unless ref $self;
  $self->setup() unless $self->{setup};
  my $desc = "";
  print STDERR "Hunting for files in distribution\n" if ${$self->{'_verbose'}};

  #Files for use for a description.  Names are relative to package
  #base.  Are there more names which work good?  BLURB?  INTRO?

  my (@doc_list) = ( $self->{expand_dir} ."/". "README" ,
		     $self->{expand_dir} ."/". "DESCRIPTION" );

#we just use absolute paths
#  my $dirpref = $self->{expand_dir};

  my $handler=sub {
    m/\.p(od|m|l)$/ or return;
    my $name=$File::Find::name;
#    $name =~ s/^$dirpref//;
    push @doc_list, $name;
  };
  &File::Find::find($handler, $self->{expand_dir});

  $desc=$self->_check_files_for_desc(\@doc_list);

  unless ( $desc ) {
    warn "Failed to generate any description for "
      . $self->{package_name} . ".\n";
    return undef;
  }

  #FIXME: what's the best way to clean up whitespace?  Is it needed at all?
  #bear in mind that both perl descriptions and rpm special case
  #indentation with white space to mean something like \verbatim

  $desc=~s/^[\t ]*//mg;		#space at the start of lines
  $desc=~s/[\t ]*$//mg;		#space at the end of lines
  $desc=~s/^[_\W]*//s ; #blank  punctuation lines at the start
  $desc=~s/\s*$//;		#blank lines at the end.

  return $desc;
}

=head2 doc_files

We give a list of files or directories which it is good to treat as
documentation and include within any binary distribution.

We like to include usage documentation, copyrights and release
information.  Probably we don't care too much about implementation
documentation.  Right now we just doo fairly simple file name guessing
in the top level directory of the distribution.

doc_files returns a list of files to a list context and a reference to
an array of files to a scalar context.

=cut

my $docre='(?x) (^README)
                |(^C((?i)OPY((ING)|(RIGHT))))|(LICENSE$)
                |(^doc(s|u.*)?)
                |(^FAQ)
                |(^(?i)notes$)
                |(^(?i)todo$)
                |(^(Changes)|(NEWS)$)
                |((?i)examples?)';

sub doc_files() {
  my $self = shift;
  $self->setup() unless $self->{setup};
  my $old_dir = Cwd::cwd();
  my @docs = ();
  my $return="";
  opendir (BASEDIR , $self->{expand_dir})
    || die "can't open package main directory $self->{expand_dir} $!";
  my @files=readdir (BASEDIR);
  @docs= grep {m/$docre/i} @files;
  print STDERR "Found the following documentation files\n" ,
    join ("  " , @docs ), "\n" if ${$self->{'_verbose'}};
  return wantarray ? @docs : \@docs;
}

=head2 requires / provides

These functions would try to guess which perl modules are needed to
run this one / which perl libraries this module provides..  They
aren't implmeneted yet.

Currently we haven't distinguished pre-requisite modules needed to run
the module from ones needed merely to install it.

There is code in perl.prov and perl.req in the lib directory of RPM
(the RedHat Package Manager) which can determine this information,
however, it requires the module to have been build correctly and
installed in a temporary directory hierarchy.

=cut

sub requires {
  die "Module::Metainfo::requires() isn't yet implemented";
}

sub provides {
  die "Module::Metainfo::provides() isn't yet implemented";
}

=head1 FUTURE FUNCTIONS

There are a number of other things which should be implemented.  These
can be guessed from looking at the possible meta-information which can
be stored in the RPM or DPG formats, for example.  Examples include

=over 4

=item *

copyright - GPL / as perl / redistributable / etc.

=item *

application area - Database / Internet / WWW / HTTP etc.

=item *

suggests - related applications

=back

In many cases this data is generated currently by package building
tools simply by using a fixed string.  The function should do better
than that in almost all cases or else it is't worth having...

=head1 FUTURE DEVELOPMENT

Incorporate a mechanism for deliberately storing meta information
inside perl modules, e.g. by adding a directory structure inside.  I
already have a prototype for this included into makerpm.

=head1 COPYRIGHT

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified in the
Perl README.

=head1 AUTHOR

Michael De La Rue.

=head1 SEE ALSO

L<pm-metainfo>

=cut

42;
