package POE::Component::SmokeBox::Recent;
$POE::Component::SmokeBox::Recent::VERSION = '1.54';
#ABSTRACT: A POE component to retrieve recent CPAN uploads.

use strict;
use warnings;
use Carp;
use POE qw(Component::SmokeBox::Recent::HTTP Component::SmokeBox::Recent::FTP Wheel::Run);
use URI;
use HTTP::Request;
use File::Spec;

sub recent {
  my $package = shift;
  my %opts = @_;
  $opts{lc $_} = delete $opts{$_} for keys %opts;
  croak "$package requires a 'url' argument\n" unless $opts{url};
  croak "$package requires an 'event' argument\n" unless $opts{event};
  $opts{rss} = 0 unless $opts{rss};
  my $options = delete $opts{options};
  my $self = bless \%opts, $package;
  $self->{recent} = [];
  $self->{uri} = URI->new( $self->{url} );
  croak "url provided is of an unsupported scheme\n"
	unless $self->{uri}->scheme and $self->{uri}->scheme =~ /^(ht|f)tp|file$/;
  $self->{session_id} = POE::Session->create(
	object_states => [
	   $self => [ qw(_start _process_http _process_ftp _process_file _recent _sig_child _epoch _epoch_fail) ],
	   $self => {
		      http_sockerr  => '_get_connect_error',
		      http_timeout  => '_get_connect_error',
		      http_response => '_http_response',
		      ftp_sockerr   => '_get_connect_error',
		      ftp_error     => '_get_error',
		      ftp_data      => '_get_data',
		      ftp_done      => '_get_done', },
	],
	heap => $self,
	( ref($options) eq 'HASH' ? ( options => $options ) : () ),
  )->ID();
  return $self;
}

sub _start {
  my ($kernel,$sender,$self) = @_[KERNEL,SENDER,OBJECT];
  $self->{session_id} = $_[SESSION]->ID();
  if ( $kernel == $sender and !$self->{session} ) {
	croak "Not called from another POE session and 'session' wasn't set\n";
  }
  my $sender_id;
  if ( $self->{session} ) {
    if ( my $ref = $kernel->alias_resolve( $self->{session} ) ) {
	$sender_id = $ref->ID();
    }
    else {
	croak "Could not resolve 'session' to a valid POE session\n";
    }
  }
  else {
    $sender_id = $sender->ID();
  }
  $kernel->refcount_increment( $sender_id, __PACKAGE__ );
  $kernel->detach_myself();
  $self->{sender_id} = $sender_id;
  if ( $self->{epoch} ) {
    $kernel->yield( '_epoch' );
    return;
  }
  $kernel->yield( '_process_' . $self->{uri}->scheme );
  return;
}

sub _recent {
  my ($kernel,$self,$type) = @_[KERNEL,OBJECT,ARG0];
  my $target = delete $self->{sender_id};
  my %reply;
  $reply{recent} = delete $self->{recent} if $self->{recent};
  $reply{error} = delete $self->{error} if $self->{error};
  $reply{context} = delete $self->{context} if $self->{context};
  $reply{url} = delete $self->{url};
  @{ $reply{recent} } = grep { my @parts = split m!/!; $parts[3] !~ m!^perl6$!i } @{ $reply{recent} };
  my $event = delete $self->{event};
  $kernel->post( $target, $event, \%reply );
  $kernel->refcount_decrement( $target, __PACKAGE__ );
  return;
}

sub _process_http {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my @path = $self->{rss} ? ( 'modules', '01modules.mtime.rss' ) : ( 'RECENT' );
  $self->{uri}->path( File::Spec::Unix->catfile( $self->{uri}->path(), @path ) );
  POE::Component::SmokeBox::Recent::HTTP->spawn(
	uri => $self->{uri},
  );
  return;
}

sub _http_response {
  my ($kernel,$self,$response) = @_[KERNEL,OBJECT,ARG0];
  if ( $response->code() == 200 ) {
    if ( $self->{rss} ) {
      for ( split /\n/, $response->content() ) {
        next unless m#<link>(.+?)</link>#i;
        next unless m#by-authors#i;
        my ($link) = $_ =~ m#id/(.+?)</link>\s*$#i;
        next unless $link;
        unshift @{ $self->{recent} }, $link;
      }
    }
    else {
      for ( split /\n/, $response->content() ) {
        next unless /^authors/;
        next unless /\.(tar\.gz|tgz|tar\.bz2|zip)$/;
        s!authors/id/!!;
        push @{ $self->{recent} }, $_;
      }
    }
  }
  else {
    $self->{error} = $response->as_string();
  }
  $kernel->yield( '_recent', 'http' );
  return;
}

sub _process_ftp {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  my @path = $self->{rss} ? ( 'modules', '01modules.mtime.rss' ) : ( 'RECENT' );
  POE::Component::SmokeBox::Recent::FTP->spawn(
        Username => 'anonymous',
        Password => 'anon@anon.org',
        address  => $self->{uri}->host,
	      port	   => $self->{uri}->port,
	      path     => File::Spec::Unix->catfile( $self->{uri}->path, @path ),
  );
  return;
}

sub _get_connect_error {
  my ($kernel,$self,@args) = @_[KERNEL,OBJECT,ARG0..$#_];
  $self->{error} = join ' ', @args;
  $kernel->yield( '_recent', 'ftp' );
  return;
}

sub _get_error {
  my ($kernel,$self,$sender,@args) = @_[KERNEL,OBJECT,SENDER,ARG0..$#_];
  $self->{error} = join ' ', @args;
  $kernel->yield( '_recent', 'ftp' );
  return;
}

sub _get_data {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  $data =~ s![\x0D\x0A]+$!!g;
  if ( $self->{rss} ) {
    return unless $data =~ m#<link>(.+?)</link>#i;
    return unless $data =~ m#by-authors#i;
    my ($link) = $data =~ m#id/(.+?)</link>\s*$#i;
    return unless $link;
    unshift @{ $self->{recent} }, $link;
  }
  elsif ( $self->{epoch} ) {
    push @{ $self->{recent} }, $data;
  }
  else {
    return unless $data =~ /^authors/i;
    return unless $data =~ /\.(tar\.gz|tgz|tar\.bz2|zip)$/;
    $data =~ s!authors/id/!!;
    push @{ $self->{recent} }, $data;
  }
  return;
}

sub _get_done {
  my ($kernel,$self,$sender) = @_[KERNEL,OBJECT,SENDER];
  $kernel->yield( '_recent', 'ftp' );
  return;
}

sub _process_file {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{_epoch_fail};
  {
    my @segs = $self->{uri}->path_segments;
    pop @segs unless $segs[-1];
    push @segs, 'RECENT';
    $self->{uri}->path_segments( @segs );
  }
  $self->{wheel} = POE::Wheel::Run->new(
      Program => sub {
        my $path = shift;
        open my $fh, '<', $path or die "$!\n";
        while (<$fh>) {
          print STDOUT $_;
        }
        close $fh;
      },
      ProgramArgs => [ $self->{uri}->file ],
      StdoutEvent => 'ftp_data',
  );
  $kernel->sig_child( $self->{wheel}->PID(), '_sig_child' );
  return;
}

sub _epoch {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  require CPAN::Recent::Uploads;
  $self->{wheel} = POE::Wheel::Run->new(
      Program => sub {
        my $epoch  = shift;
        my $mirror = shift;
        print STDOUT $_, "\n" for
          CPAN::Recent::Uploads->recent( $epoch, $mirror );
      },
      ProgramArgs => [ $self->{epoch}, $self->{uri}->as_string ],
      StdoutEvent => 'ftp_data',
      StderrEvent => '_epoch_fail',
  );
  $kernel->sig_child( $self->{wheel}->PID(), '_sig_child' );
  return;
}

sub _epoch_fail {
  my ($kernel,$self,$data) = @_[KERNEL,OBJECT,ARG0];
  # Anything on STDERR means an error
  return if $self->{_epoch_fail};
  $self->{_epoch_fail} = 1;
  $kernel->yield( '_process_' . $self->{uri}->scheme );
  return;
}

sub _sig_child {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
  delete $self->{wheel};
  $kernel->yield( '_recent', 'file' ) unless $self->{_epoch_fail};
  $kernel->sig_handled();
}

qq[What's the road on the street?];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::SmokeBox::Recent - A POE component to retrieve recent CPAN uploads.

=head1 VERSION

version 1.54

=head1 SYNOPSIS

  use strict;
  use POE qw(Component::SmokeBox::Recent);

  $|=1;

  POE::Session->create(
	package_states => [
	  'main' => [qw(_start recent)],
	],
  );

  $poe_kernel->run();
  exit 0;

  sub _start {
    POE::Component::SmokeBox::Recent->recent(
	url => 'http://www.cpan.org/',
	event => 'recent',
    );
    return;
  }

  sub recent {
    my $hashref = $_[ARG0];
    if ( $hashref->{error} ) {
	print $hashref->{error}, "\n";
	return;
    }
    print $_, "\n" for @{ $hashref->{recent} };
    return;
  }

=head1 DESCRIPTION

POE::Component::SmokeBox::Recent is a L<POE> component for retrieving recently uploaded CPAN distributions
from the CPAN mirror of your choice.

It accepts a url and an event name and attempts to download and parse the RECENT file from that given url.

It is part of the SmokeBox toolkit for building CPAN Smoke testing frameworks.

=head1 CONSTRUCTOR

=over

=item recent

Takes a number of parameters:

  'url', the full url of the CPAN mirror to retrieve the RECENT file from, only http ftp and file are currently supported, mandatory;
  'event', the event handler in your session where the result should be sent, mandatory;
  'session', optional if the poco is spawned from within another session;
  'context', anything you like that'll fit in a scalar, a ref for instance;
  'rss', set to a 'true' value to retrieve from the rss file instead of RECENT file.
  'epoch', an epoch timestamp less than the current time but greater than an year ago.

The 'session' parameter is only required if you wish the output event to go to a different
session than the calling session, or if you have spawned the poco outside of a session.

The 'rss' parameter if set will indicate that the poco should retrieve recent uploads from the
C<modules/01modules.mtime.rss> file instead of the C<RECENT> file. The rss file contains the
150 most recent uploads to CPAN and is more up to date than the C<RECENT> file.

The 'epoch' parameter should be a valid epoch timestamp less than the current time but greater than
a year ago. Setting this will cause the component to use L<CPAN::Recent::Uploads> to obtain a list
of distributions uploaded since the 'epoch' time given. This enables more grandular control of
listing dists than simply retrieving the C<RECENT> file.

The poco does it's work and will return the output event with the result.

=back

=head1 OUTPUT EVENT

This is generated by the poco. ARG0 will be a hash reference with the following keys:

  'recent', an arrayref containing recently uploaded distributions;
  'error', if something went wrong this will contain some hopefully meaningful error messages;
  'context', if you supplied a context in the constructor it will be returned here;

=head1 KUDOS

Andy Armstrong for helping me to debug accessing his CPAN mirror.

=head1 SEE ALSO

L<POE>

L<http://cpantest.grango.org/>

L<POE::Component::Client::HTTP>

L<POE::Component::Client::FTP>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
