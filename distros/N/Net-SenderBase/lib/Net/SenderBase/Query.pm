# $Id: Query.pm,v 1.3 2003/07/04 15:44:34 matt Exp $

package Net::SenderBase::Query;
use strict;
use vars qw($TIMEOUT);

use Net::SenderBase::Results;
use Socket;

$TIMEOUT = 10;

sub new {
    my $class = shift;
    my %attrs = @_;

    $attrs{Address} || die "No 'Address' attribute in call to new()";
    if ($attrs{Address} !~ /^\d+\.\d+\.\d+\.\d+$/) {
        # assume it is a hostname instead of an IP
        $attrs{Address} = inet_ntoa(scalar(gethostbyname($attrs{Address})||pack("N", 0)));
    }

    $attrs{Timeout} ||= $TIMEOUT;
    
    my $type = uc($attrs{Transport}) || 'DNS';
    my $query_class = "${class}::${type}";
    load_module($query_class);
    
    return $query_class->new(%attrs);
}

sub load_module {
    my $module = shift;
    $module =~ s/::/\//g;
    $module .= ".pm";
    require $module;
}

1;
__END__

=head1 NAME

Net::SenderBase::Query - SenderBase query module

=head1 SYNOPSIS

  my $query = Net::SenderBase::Query->new(
      Transport => 'dns',
      Address => $ip,
  );
  my $results = $query->results;

=head1 DESCRIPTION

This module is a front-end to initiating the query.

=head2 C<new()>

  my $query = Net::SenderBase::Query->new(
      Transport => 'dns',
      Address => $ip,
      Host => 'test.senderbase.org',
      Timeout => 10,
  );

This method constructs a new query object. If an error occurs while
constructing the query an exception will be thrown.

The default transport if not given is 'dns'. The transport is not
case sensitive.

The C<Address> attribute is required.

The default C<Host> is 'test.senderbase.org'.

The default C<Timeout> is 5 seconds.

=head2 C<results()>

  my $results = $query->results();

This method returns a C<Net::SenderBase::Results> object containing
the data for this IP address. If there was no data available it returns
undef. If an error occured obtaining the results an exception will be
thrown.

=head1 SEE ALSO

L<Net::SenderBase::Results>

=cut

