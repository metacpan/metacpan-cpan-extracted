package Net::Dynect::REST::RData;
# $Id: RData.pm 177 2010-09-28 00:50:02Z james $
use strict;
use warnings;
use overload '""' => \&_as_string;
use Carp;
our $AUTOLOAD;
our $VERSION = do { my @r = (q$Revision: 177 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head1 NAME

Net::Dynect::REST::RData - Record Data returned as a result of querying Dynect

=head1 SYNOPSIS

 use Net::Dynect::REST::ARecord;
 my @records = Net::Dynect::REST::ARecord->find(connection => $dynect, zone => $zone, fqdn => $fqdn);
 foreach (@arecords) {
   print $_->rdata;
   my @fields = $_->rdata->data_keys;
   my $address = $_->rdata->address;
 }

=head1 METHODS

=head2 Creating

=over 4

=item new

This constructor takes the data as decoded from the response.

=back

=cut 

sub new {
    my $proto = shift;
    my $self  = bless {}, ref($proto) || $proto;
    my %args  = @_;
    $self->rdata( $args{data} ) if defined $args{data};
    return $self;
}

sub rdata {
    my $self = shift;
    if (@_) {
        my $new = shift;
        $self->{data} = $new;
    }
    return $self->{data};
}

=head2 Attributes

=over 4 

=item data_keys

This returns the names of the keys of the data returned. 

=item other, random, names

As the data varies depending on the request given, so does the value returned in the response. Hence the data may have a key of B<zone>, or B<ttl>, or anthing else.

=cut

sub data_keys {
    my $self = shift;
    return keys %{ $self->{data} };
}

sub AUTOLOAD {
    my $self = shift;
    if ( ref($self) ne "Net::Dynect::REST::RData" ) {
        carp "This should be a Net::Dynect::REST::RData";
        return;
    }
    my $name = $AUTOLOAD;
    return unless defined $self->{data};
    $name =~ s/.*://;    # strip fully-qualified portion
    if (@_) {
      my $new = shift;
      warn "Trying to set $name = $new";
      if ($name eq "address") {
	return unless __PACKAGE__->_is_valid_ipv4($new) || __PACKAGE__->_is_valid_ipv6($new);
      } elsif ($name eq "txtdata") {
	return unless __PACKAGE__->_is_valid_txtdata($new);
      } elsif ($name eq "cname") {
	return unless __PACKAGE__->_is_valid_fqdn($new);
      }
      $self->{data}->{$name} = $new;
    }
    return $self->{data}->{$name} if defined $self->{data}->{$name};
}

sub _is_valid_ipv4 {
    my $address = shift;
    require "Net::IP";
    my $ip = Net::IP->new($address);
    return $ip->ip_is_ipv4;
    return;
}

sub _is_valid_ipv6 {
    my $address = shift;
    require "Net::IP";
    my $ip = Net::IP->new($address);
    return $ip->ip_is_ipv6;
}

sub _is_valid_txtdata {
    my $text = shift;
    return length($text) <= 255;
}

sub _is_valid_fqdn {
    my $fqdn = shift;
    return 1 if $fqdn =~ /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$/;
}

sub _as_string {
    my $self = shift;
    my @texts;
    foreach ( $self->data_keys ) {
        push @texts, sprintf "%s: %s", $_, $self->$_;
    }
    return join( ', ', @texts );
}

=back

=head1 SEE ALSO

L<Net::Dynect::REST>, L<Net::Dynect::REST::info>.

=head1 AUTHOR

James bromberger, james@rcpt.to

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by James Bromberger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.




=cut

1;
