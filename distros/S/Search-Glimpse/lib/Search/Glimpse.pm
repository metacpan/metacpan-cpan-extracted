package Search::Glimpse;
#
# $Id: Glimpse.pm 9758 2011-03-18 20:59:13Z ambs $
#
# A tool for searching in a glimpse index via the glimpseserver system.
# It unfortunately requires opening a pipe to glimpse but that's not 
# the end of the world I suppose.
#
# A better version would write directly to the glimpserver socket
# but I don't feel like having time to mess with decoding that.
#
# Chris Dent for Kiva Networking <cdent@kiva.net> November 3, 1997
#
# Currently maintained by Alberto Simões <ambs@cpan.org> February 9, 2004
#
use 5.006001;
use strict;
use warnings;

use base 'Exporter';
use Search::Glimpse::ConfigData;
use IO::File;


our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.04';

our $GLIMPSE_STATIC_ARGS = '-C -J #SERVER# -i -y -w -L #HITS#';
our $GLIMPSE_FILTER = '-F';
our $DEBUG = 0;



=head1 NAME

Search::Glimpse - Perl extension to communicate with Glimpse server

=head1 SYNOPSIS

  use Search::Glimpse;

  my $glimpse = Search::Glimpse->new;

  my @results = $glimpse->search("search this string");

=head1 ABSTRACT

  This module is an extension to use glimpse server from Perl.

=head1 DESCRIPTION

Quick hack to connect to glimpse server.

=cut




=head2 new

Creates a new glimpse object.

=cut

sub new {
  # create the object
  # and establish the file extension filter if needed
  my $class = shift;
  my $self = {};
  $self->{'hits'} = 0;
  $self->{'files'} = 0;

  # get the incoming parms
  my %parms = @_;
  $self->{server} = $parms{server} || "localhost";
  $self->{nr_hits} = $parms{nr_hits} || 100;

  my $ext_filter = $parms{'ext_filter'};
  my $sto_filter = $parms{'sto_filter'};

  # can't have both or we're buggered
  return undef if ($sto_filter && $ext_filter);

  # set the filter
  if ($ext_filter) {
    $self->{'filter'} = "$GLIMPSE_FILTER '\.$ext_filter" . '$' . "'";
  }
  if ($sto_filter) {
    # $ext_filter = $STO_EXT;
    # $self->{'filter'} =
    # "$GLIMPSE_FILTER '/$sto_filter#\.$ext_filter" . '$' . "'";
    #
    # at the moment I'll maintain this commented, as STO_EXT is not
    # defined, and I do not know how to define it.
  }

  return bless $self, $class;
}

=head2 search

Search on a glimpse object

=cut

sub search {
  # open the glimpse process and get's it output
  # return 'ERROR' if there is an error
  my $self = shift;
  my $string = shift;
  my ($openstring, $infostring);
  my @results;

  if (0) {
    # if there is an apostrophic (?) thing on the end of a word,
    # remove it
    $string =~ s/\'\w\b//;

    # deal with accepting booleans
    $string =~ s/\s*\band\b\s*/;/gi;
    $string =~ s/\s*\bor\b\s*/,/gi;
    $string =~ s/\s*\bnot\b\s*/;~/gi;

    # turn the remaining search string into an and
    $string =~ s/\s+/;/g;

    # clean up the string somewhat
    $string =~ s/^\s+//g; # whitespace at start of line
    $string =~ s/\s+$//g; # whitespace at end of line
    # seems like we are accepting nearly everything at this point
    # that can't possibly be good, except we are single quoting below
    # and don't allow quotes in the search
    # ($string) = ($string =~ m#^([\w\s;~,\-<>/\$\?]+)$#);
  }


  print STDERR "$string\n" if $DEBUG;

  # bug out if there's not string left
  return undef unless ($string);

  $self->{'filter'}||="";

  my $GLIMPSE_BIN = Search::Glimpse::ConfigData->config('glimpse');
  $openstring = "$GLIMPSE_BIN $GLIMPSE_STATIC_ARGS " . $self->{'filter'} .
    " \'" . $string . "\'";

  $openstring =~ s/#SERVER#/$self->{server}/;
  $openstring =~ s/#HITS#/$self->{nr_hits}/;

  my $fh = new IO::File;

  print STDERR "$openstring\n" if $DEBUG;

  ($fh->open("$openstring 2>&1|"))  || return undef;

  # Não esto ua receber a info-string..., tv por não estar a tratar
  # ficheiros mas matches...

  # $infostring = <$fh>;
  # ($self->{'hits'}, $self->{'files'}) = ($infostring =~ /(\d+)[^0-9]*(\d+)/);

  @results = <$fh>;
  $fh->close;
  # if the error code from glimpse is not 0 then the
  # server is probably down or rereading its index
  # this is probably not the best way to do this, but hey, well
  if ($? != 0) {
    undef(@results);
    push(@results, "ERROR");
  }

  return @results;
}

=head2 hits

Returns the number of hits...

=cut

sub hits {
  my $self = shift;
  return $self->{'hits'};
}

=head2 files

Returns the number of files...

=cut

sub files {
  my $self = shift;
  return $self->{'files'};
}




1;
__END__

=head1 SEE ALSO

Glimpse can be downloaded from C<http://www.webglimpse.net>

=head1 AUTHOR

This module author is Chris Dent.
At the moment, is being maintained by Alberto Simoes C<ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1997-2004 by Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
