package TeX::AutoTeX::Log;

#
# $Id: Log.pm,v 1.10.2.5 2011/01/27 18:42:28 thorstens Exp $
# $Revision: 1.10.2.5 $
# $Source: /cvsroot/arxivlib/arXivLib/lib/TeX/AutoTeX/Log.pm,v $
#
# $Date: 2011/01/27 18:42:28 $
# $Author: thorstens $
#

use strict;
### use warnings;
use Carp;
use TeX::AutoTeX::Exception;

our ($VERSION) = '$Revision: 1.10.2.5 $' =~ m{ \$Revision: \s+ (\S+) }x;

use IO::Handle; #for autoflush

sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self  = {
	       logfile => 'auto_gen_ps.log',
	       dir     => undef,
	       logfh   => undef,
	       dupefh  => undef,
	       verbose => 0,
	       @_
	      };
  if (!(defined $self->{dir} && -d $self->{dir})) {
    throw TeX::AutoTeX::FatalException 'TeX::AutoTeX::Log::new requires a directory (dir) option to write the log to'
  }
  bless $self, $class;
  $self->{dupefh}->autoflush(1) if $self->{dupefh};
  return $self;
}

sub open_logfile {
  my $self = shift;
  if (!$self->{logfile}) {
    throw TeX::AutoTeX::FatalException q{Can't open log file without a name.};
  }
  open($self->{logfh}, '>', "$self->{dir}/$self->{logfile}")
    || throw TeX::AutoTeX::FatalException "Could not open log file '$self->{logfile}' for writing.";
  return 1;
}

sub close_logfile {
  my $self = shift;
  if ($self->{logfh}) {
    close $self->{logfh} || carp q{couldn't close logfile};
    return 1;
  }
  return;
}

sub error {
  my ($self, $msg) = @_;
  $msg =~ s/\n\s*$//;
  $self->__logit('error', "$msg\n*** AutoTeX ABORTING ***\n");
  throw TeX::AutoTeX::FatalException $msg;
}

sub verbose {
  my ($self, $msg) = @_;
  $self->__logit('verbose', $msg) if $self->{verbose};
  return;
}

sub __logit {
  my ($self, $level, $msg) = @_;
  $msg = "[$level]: $msg\n";
  if ($self->{logfh}) {
    print {$self->{logfh}} $msg;
  }
  if ($self->{dupefh}) {
    print {$self->{dupefh}} $msg;
  }
  return;
}

sub to_stringref {
  my $self = shift;
  seek $self->{logfh}, 0, 1; # flush buffered log messages
  if (open my $LOG, '<', "$self->{dir}/$self->{logfile}") {
    my $logcontent;
    {
      local $/ = undef;
      $logcontent = <$LOG>;
    }
    close $LOG || carp q{couldn't close logfile};
    return \$logcontent;
  }
  carp q{can't open logfile};
  return;
}

1;

__END__

=for stopwords AutoTeX STDOUT logfile logfilehandle www-admin Schwander arXiv arxiv.org perlartistic

=head1 NAME

TeX::AutoTeX::Log - log handling for TeX::AutoTeX

=head1 DESCRIPTION

Logging object for AutoTeX.

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

=head2 new()

Constructor with facilities to override all settings via input hash. In
particular, a second file handle may be supplied to duplicate the output,
e.g.

C<< my $log=TeX::AutoTeX::Log->new( dupefh => \*STDOUT); >>

To duplicate to STDOUT.

A call to open_logfile must be made to actually create and start writing to a
logfile. This is separated to that the Log object can be created before
changing to the appropriate directory to write the logfile.

=head2 open_logfile()

Open the logfile. This action will overwrite an existing file of the same
name.

=head2 close_logfile()

Attempts to close the logfile, if a logfilehandle exists.

=head2 error

Log an error message and croak

=head2 verbose

Log message if verbose is set true

=head2 to_stringref

$log->to_stringref() returns a scalar reference to the contents of the log file

=head3 internal method __logit

Log a generic message. Called by the various functions for different types of
messages. Not intended to be called externally.

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
