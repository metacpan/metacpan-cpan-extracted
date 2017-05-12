package Net::Google::tool;
use strict;

$Net::Google::tool::VERSION = '1.1';

use Carp;

my %_queries = ();

sub init {
  my $self    = shift;
  my $service = shift;

  # old skool / new skool
  # arguments.

  my $first_arg   = shift;
  my $poss_second = shift;

  # What everyone will actually
  # play with.

  my $args = undef;

  #

  if (ref($first_arg) eq "GoogleSearchService") {
    $self->{'_service'} = $first_arg;
    $args = $poss_second;
  }

  else {
    $args = $first_arg;

    require Net::Google::Service;

    $self->{'_service'} = Net::Google::Service->$service($args);
    if (! $self->{'_service'}) { return 0; }
  }

  #

  if (! $args->{'key'}) {
    carp "You must define a key";
    return 0;
  }

  $self->key($args->{'key'});

  #

  return $args;
}

sub _queries {
    my $self  = shift;
    my $count = shift;

    my $key = $self->key();

    if (! exists($_queries{$key})) {
	$_queries{$key} = 0;
    }

    if (int($count)) {
	$_queries{$key} += int($count);
    }

    return $_queries{$key};
}

sub queries_exhausted {
    my $self = shift;
    return ($self->_queries() >= 1000) ? 1 : 0;
}

sub key {
  my $self = shift;
  my $key  = shift;

  if (defined($key)) {
    $self->{'_key'} = $key;
  }

  return $self->{'_key'};
}

sub http_proxy {
  my $self = shift;
  my $uri  = shift;

  if ($uri) {
    # See notes in Net::Google::Service->_soap()
    shift->{'_service'}->transport()->proxy($uri)->proxy(http=>$uri);
    $self->{'_http_proxy'} = $uri;
  }

  return $self->{'_http_proxy'};
}

return 1;

__END__

=head1 NAME

Net::Google::tool - base class for Net::Google service classes.

=head1 SYNOPSIS

 Ceci n'est une boite noire.

=head1 DESCRIPTION

Base class and shared methods for Net::Google service classes.

=head1 VERSION

1.1

=head1 DATE

$Date: 2005/03/26 20:49:03 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger>

=head1 BUGS

Please report all bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2003-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same 
terms as Perl itself.

=cut
