use strict;
use warnings;
package SMS::Send::Nexmo;

our $VERSION = '0.23';
# ABSTRACT: SMS::Send backend for the Nexmo.com SMS service.

use SMS::Send::Driver;
use Nexmo::SMS;

our @ISA = qw/SMS::Send::Driver/;
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $URL = 'https://rest.nexmo.com/sms/json';

sub new {
  my $pkg = shift;
  my %p = @_;
  exists $p{_username} or die $pkg."->new requires _username parameter\n";
  exists $p{_password} or die $pkg."->new requires _password parameter\n";
  exists $p{_from} or die $pkg."->new requires _from parameter\n";
  exists $p{_server} or $p{_server} = $URL;
  exists $p{_verbose} or $p{_verbose} = 1;
  my $self = \%p;
  bless $self, $pkg;
  $self->{_nexmo} = Nexmo::SMS->new(
      server   => $p{_server},
      username => $p{_username},
      password => $p{_password},
  );
  return $self;
}

sub send_sms {
  my $self = shift;
  my %p = @_;
  $p{to} =~ s/^\+//;
  $p{to} =~ s/[- ]//g;

  my $sms = $self->{_nexmo}->sms(
      text => $p{text},
      from => $self->{_from},
      to   => $p{to},
      );

  my $response = $sms->send;

  unless ($response->is_success) {
    warn "Failure: " . $sms->errstr . "\n" if ($self->{_verbose});
    return 0;
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SMS::Send::Nexmo - SMS::Send backend for the Nexmo.com SMS service.

=head1 VERSION

version 0.23

=head1 SYNOPSIS

This is an SMS::Send backend for the L<http://nexmo.com> SMS service. 
You're not supposed to use this module directly, you should use
SMS::Send instead. 

=head1 DESCRIPTION

It's easy!

  # Create a sender
  my $send = SMS::Send->new( 'Nexmo',
                             _username => '12345ab6',
                             _password => 'ab1cd2e3',
                             _from     => '0031715793800',
                            );

  # Send a message
  $send->send_sms(
     text => 'Hi there',
     to   => '+31 6 45742418',
  );

This module uses L<Nexmo::SMS> as backend. If you need more advanced
functions than just sending messages; please use L<Nexmo::SMS> directly.

=head1 AUTHOR

Michiel Beijen <michielb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by OTRS BV.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
