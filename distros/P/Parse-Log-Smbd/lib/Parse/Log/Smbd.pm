package Parse::Log::Smbd;

use warnings;
use strict;
use Carp;
use IO::File;
use Devel::CheckOS qw/ os_is die_unsupported /;

die_unsupported() if os_is('MicrosoftWindows');

=head1 NAME

Parse::Log::Smbd - parse log.smbd files to fetch usernames and connections to network shares

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module retrieves users successfully authenticated and connections to SMB/CIFS network shares from Samba C<log.smbd> files.

    use Parse::Log::Smbd;

    my $log = Parse::Log::Smbd->new( '/var/log/log.smbd' );

    my @users = $log->users;
    my @shares = $log->shares;

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new C<Parse::Log::Smbd> object, with the intended log filename as argument.

=cut

sub new {
    my ($class, $file) = @_;
    croak "Log filename missing" unless defined $file;

    my $self = {};

    my $fh = IO::File->new("< $file");
    croak "Can't read from $file: $!" unless $fh;

    $self->{fh} = $fh;

    _parse_log($self);

    bless ($self, $class);
    return $self;
}

sub _parse_log {
  my $self = shift;
  my $fh = $self->{fh};

  while (<$fh>) {
    if (/authentication for user \[(\w+)\].*?/) {
      push @{ $self->{users} }, $1;
    }
    if (/connect to service (\w+).*?/) {
      push @{ $self->{shares} }, $1;
    }
  }
}

=head2 users

Lists users that authenticated successfully to the smbd server. Returns a sorted list of unique usernames.

=cut

sub users {
  my $self = shift;

  undef my %seen;
  return sort grep(!$seen{$_}++, @{ $self->{users} });
}

=head2 shares

Lists successful connections to network shares. Returns a sorted list of unique shares.

=cut

sub shares {
  my $self = shift;

  undef my %seen;
  return sort grep(!$seen{$_}++, @{ $self->{shares} });
}

=head1 AUTHOR

Ari Constancio, C<< <affc at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-log-smbd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Log-Smbd>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Log::Smbd


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Log-Smbd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Log-Smbd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Log-Smbd>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Log-Smbd/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to the Samba Team (L<http://samba.org>) for a great software.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ari Constancio.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Parse::Log::Smbd
