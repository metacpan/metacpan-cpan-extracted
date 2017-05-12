=head1 NAME

Prospect::Client -- base class for Prospect::LocalClient and 
Prospect::SoapClient.
S<$Id: Client.pm,v 1.15 2003/11/07 00:46:38 cavs Exp $>

=head1 SYNOPSIS

This is an abstract class and is intended only for subclassing.

=head1 DESCRIPTION

B<Prospect::Client> is the abstract base class for Prospect::LocalClient and 
Prospect::SoapClient. Not intended to be instantiated directly.

=head1 ROUTINES & METHODS

=cut

package Prospect::Client;
use strict;
use warnings;
use File::Temp;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.15 $ =~ /(\d+)\.(\d+)/ );


#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:      new()
 Purpose:   constructor
 Arguments: 'tempdir' => directory to create temporary files (optional) 
 Returns:   Prospect::Client

=cut

sub new {
  my $type = shift;
  my $self = {};
  if (ref $_[0])
    { %{$self} = %{$_[0]};  }
  else
    { %{$self} = @_; }
  bless($self,$type);

  if ( ! defined $self->{'tempdir'} ) {
    $self->{tempdir} = File::Temp::tempdir(
      '/tmp/'.__PACKAGE__.'-XXXX',
      CLEANUP=>!$ENV{DEBUG} );
    defined $self->{tempdir}
    or throw Prospect::RuntimeError( "couldn't create temporary directory" );
  }
  if ( ! -w $self->{tempdir} ) {
    throw Prospect::RuntimeError( "tempdir (" . $self->{tempdir} . ") is not writeable" );
  }

  print(STDERR "tempdir: " . $self->{tempdir} . "\n") if $ENV{'DEBUG'};

  if (not defined $self->{cacheLimit})
  { $self->{cacheLimit} = 25; }

  return $self;
}



#-------------------------------------------------------------------------------
# _tempfile()
#-------------------------------------------------------------------------------

=head2 _tempfile()

 Name:      _tempfile()
 Purpose:   return the filename of a temporary file
 Arguments: suffix for filename (optional)
 Returns:   filename

=cut

sub _tempfile {
  my $self = shift;
  my $sfx = @_ ? ".$_[0]" : undef;
  return File::Temp::tempfile( DIR=>$self->{tempdir}, SUFFIX=>$sfx, UNLINK=>0 );
}


#-------------------------------------------------------------------------------
# _get_cache_file()
#-------------------------------------------------------------------------------

=head2 _get_cache_file()

 Name:      _get_cache_file()
 Purpose:   return the value for a given key in a given cache
 Arguments: key, cache name
 Returns:   value

=cut

sub _get_cache_file {
  my ($self,$key,$cacheName) = @_;

  if ( defined $self->{'cache'}{$cacheName}{$key}{'fn'}) {
    return $self->{'cache'}{$cacheName}{$key}{'fn'};
  } else {
    return;
  }
}


#-------------------------------------------------------------------------------
# _put_cache_file()
#-------------------------------------------------------------------------------

=head2 _put_cache_file()

 Name:      _put_cache_file()
 Purpose:   put a filename into a given cache using a given key
 Arguments: key, cache name, value
 Returns:   value

=cut

sub _put_cache_file {
  my ($self,$key,$cacheName,$fn) = @_;

  if ( !defined $self->{'cache'}{$cacheName} ) {
     $self->{'cache'}{$cacheName} = {};
 }
  my $cache = $self->{'cache'}{$cacheName};

  # cache this result
  print(STDERR "## caching $fn in '$cacheName' file cache using a key of $key ...\n") if $ENV{DEBUG};
  $cache->{$key}{'fn'} = $fn;
  $cache->{$key}{'timestamp'} = time;

  # expire oldest
  if ( defined $cache and ( exists $self->{cacheLimit} ) and ( scalar keys %{$cache} >= $self->{cacheLimit} ) ) {
    foreach my $key ( sort { $cache->{$a}{'timestamp'} <=> $cache->{$b}{'timestamp'} } keys %{$cache}  ) {
      print STDERR "deleting $key because it is the oldest key: " . $cache->{$key}{'timestamp'} . "\n" if $ENV{DEBUG};
      print STDERR "unlinking " . $cache->{$key}{'fn'} . "\n" if $ENV{DEBUG};
      unlink $cache->{$key}{'fn'};
      delete $cache->{$key};
      last;
    }
  }
  return;
}


=pod

=head1 BUGS

=head1 SEE ALSO

 Prospect::LocalClient
 Prospect::SoapClient

=cut

1;
