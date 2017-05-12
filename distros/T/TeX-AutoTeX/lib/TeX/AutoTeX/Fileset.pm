package TeX::AutoTeX::Fileset;

#
# $Id: Fileset.pm,v 1.8.2.4 2011/01/03 04:06:00 thorstens Exp $
# $Revision: 1.8.2.4 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/Fileset.pm,v $
#
# $Date: 2011/01/03 04:06:00 $
# $Author: thorstens $
#

use strict;
### use warnings;
use Carp;

our ($VERSION) = '$Revision: 1.8.2.4 $' =~ m{ \$Revision: \s+ (\S+) }x;

use TeX::AutoTeX::File;

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = {
              log      => undef,
	      dir      => undef,
              cache    => {},
              local_hyper_transform => undef,
	      override => {
			   ignore  => 'TYPE_IGNORE',
			   include => 'TYPE_INCLUDE',
			  },
              @_
	     };
  if (!defined $self->{log}) {
    throw TeX::AutoTeX::FatalException 'No log configuration supplied';
  }
  if (!defined $self->{dir}) {
    throw TeX::AutoTeX::FatalException 'No directory specified';
  }
  bless $self, $class;
}

sub new_File {
  my ($self, $filename) = @_;

  if (!defined $filename) {
    throw TeX::AutoTeX::FatalException 'no filename provided to new_File()';
  }
  if ($self->{cache}->{$filename}) {
    return $self->{cache}->{$filename};
  }
  $self->{cache}->{$filename} = TeX::AutoTeX::File->new($self, $filename);
}

sub override {
  my ($self, $type) = @_;
  return $self->{override}->{$type};
}

1;

__END__

=for stopwords Fileset hypertex Accessor arxiv.org perlartistic dir www-admin Schwander

=head1 NAME

TeX::AutoTeX::Fileset

=head1 DESCRIPTION

A collection of TeX::AutoTeX::File objects that includes context and
caching information.

=head1 SUBROUTINES/METHODS

=head2 new( log => $logobject, dir => $directory)

Creates a new Fileset object. Call as AutoTex::Fileset->new(log => $log, dir
=> $directory) where $log is a reference to an TeX::AutoTeX::Log object and
$directory is the top level directory of the material to be processed.

Instance data:

=over 4

=item cache - Used to cache existing File objects, will be used by the
Fileset::new_File method to return reference to an existing File object if
one already exists. Otherwise call will be passed on to File::new.

=item log - reference to an TeX::AutoTeX::Log object

=item dir - top level directory in which the collection of files resides

=item local_hyper_transform - an instance of a C<Filter> class with a
C<filter> method used to provide a local line-by-line transformation of TeX
source files executed after standard transformations to automatically use
hypertex

=item override - possible overrides of file types

=back

=head2 new_File($filename)

Get a File object for the current $filename within this Fileset context.
returns a reference to a cached File object if it is already known.

=head2 override($type)

Accessor to override data

=head1 HISTORY

 AutoTeX automatic TeX processing system
 Copyright (c) 1994-2006 arXiv.org and contributors

 AutoTeX is supplied under the GNU Public License and comes
 with ABSOLUTELY NO WARRANTY; see COPYING for more details.

 AutoTeX is an automatic TeX processing system designed to
 process TeX/LaTeX/AMSTeX/etc source code of papers submitted
 to the arXiv.org (nee xxx.lanl.gov) e-print archive. The
 portable part of this code has been extracted and is made
 available in the hope that it will be useful to other projects
 and that the input of others will benefit arXiv.org.

 Code developed and contributed to by Tanmoy Bhattacharya, Rob
 Hartill, Mark Doyle, Thorsten Schwander, and Simeon Warner.
 Refactored to separate generic code from arXiv.org specific code
 by Stephen Marsh, Michael Fromerth, and Simeon Warner 2005/2006.

 Major cleanups and algorithmic improvements/corrections by
 Thorsten Schwander 2006 - 2011

=head1 BUGS AND LIMITATIONS

Please report bugs to L<www-admin|http://arxiv.org/help/contact>

=head1 AUTHOR

See history above. Current maintainer: Thorsten Schwander for
L<arXiv.org|http://arxiv.org/>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 - 2011 arxiv.org L<http://arxiv.org/help/contact>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See
L<perlartistic|http://www.opensource.org/licenses/artistic-license-2.0.php>.

=cut
