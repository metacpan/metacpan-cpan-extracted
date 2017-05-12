package Net::RackSpace::CloudServers::Limits;
$Net::RackSpace::CloudServers::Limits::VERSION = '0.15';
use warnings;
use strict;
our $DEBUG = 0;
use Any::Moose;
use HTTP::Request;
use JSON;
use YAML;
use Carp;

has 'cloudservers' =>
    (is => 'rw', isa => 'Net::RackSpace::CloudServers', required => 1);
has 'totalramsize'      => (is => 'rw', isa => 'Int',);
has 'maxipgroups'       => (is => 'rw', isa => 'Int',);
has 'maxipgroupmembers' => (is => 'rw', isa => 'Int',);
has 'rate'              => (is => 'rw', isa => 'Maybe[ArrayRef]',);

no Any::Moose;
__PACKAGE__->meta->make_immutable();

sub BUILD {
    my $self = shift;
    $self->refresh();
}

sub refresh {
    my $self    = shift;
    my $request = HTTP::Request->new(
        'GET',
        $self->cloudservers->server_management_url . '/limits',
        ['X-Auth-Token' => $self->cloudservers->token]);
    my $response = $self->cloudservers->_request($request);
    return if $response->code == 204;
    confess 'Unknown error ' . $response->code
        unless scalar grep { $response->code eq $_ } (200, 203);
    my $hr = from_json($response->content);
    warn Dump($hr) if $DEBUG;

#{"limits":{"absolute":{"maxTotalRAMSize":51200,"maxIPGroupMembers":25,"maxNumServers":25,"maxIPGroups":25},"rate":[{"value":50,"unit":"DAY","verb":"POST","remaining":50,"URI":"\/servers*","resetTime":1247769469,"regex":"^\/servers"},{"value":10,"unit":"MINUTE","verb":"POST","remaining":10,"URI":"*","resetTime":1247769469,"regex":".*"},{"value":600,"unit":"MINUTE","verb":"DELETE","remaining":600,"URI":"*","resetTime":1247769469,"regex":".*"},{"value":10,"unit":"MINUTE","verb":"PUT","remaining":10,"URI":"*","resetTime":1247769469,"regex":".*"},{"value":3,"unit":"MINUTE","verb":"GET","remaining":3,"URI":"*changes-since*","resetTime":1247769469,"regex":"changes-since"}]}}
    confess 'response does not contain key "limits"'
        unless defined $hr->{limits};
    confess 'response does not contain hashref of "limits"'
        unless (ref $hr->{limits} eq 'HASH');

    confess 'response "limits" does not contain key "rate"'
        unless defined $hr->{limits}->{rate};
    confess 'response "limits", key "rate" is not an arrayref'
        unless (ref $hr->{limits}->{rate} eq 'ARRAY');
    $self->rate($hr->{limits}->{rate});

    confess 'response "limits" does not contain key "absolute"'
        unless defined $hr->{limits}->{absolute};
    confess 'response "limits", key "absolute" is not an hashref'
        unless (ref $hr->{limits}->{absolute} eq 'HASH');
    confess
        'response "limits", key "absolute" does not contain key "maxTotalRAMSize"'
        unless (defined $hr->{limits}->{absolute}->{"maxTotalRAMSize"});
    $self->totalramsize($hr->{limits}->{absolute}->{"maxTotalRAMSize"});
    confess
        'response "limits", key "absolute" does not contain key "maxIPGroups"'
        unless (defined $hr->{limits}->{absolute}->{"maxIPGroups"});
    $self->maxipgroups($hr->{limits}->{absolute}->{"maxIPGroups"});
    confess
        'response "limits", key "absolute" does not contain key "maxIPGroupMembers"'
        unless (defined $hr->{limits}->{absolute}->{"maxIPGroupMembers"});
    $self->maxipgroupmembers($hr->{limits}->{absolute}->{"maxIPGroupMembers"});
    return $self;
}

1;

__END__

=head1 NAME

Net::RackSpace::CloudServers::Limits - a RackSpace CloudServers Limits instance

=head1 VERSION

version 0.15

=head1 SYNOPSIS

  use Net::RackSpace::CloudServers;
  use Net::RackSpace::CloudServers::Limits;
  my $cs = Net::RackSpace::CloudServers->new(
    user => $ENV{CLOUDSERVERS_USER},
    key => $ENV{CLOUDSERVERS_KEY},
  );
  my $limits = Net::RackSpace::CloudServers::Limits->new(
    cloudservers => $cs,
  );
  $limits->refresh();
  print "Can still allocate ", $limits->totalramsize, " MB RAM\n";
  print "Can still use      ", $limits->maxipgroups, " IP Groups\n";
  print "Can have           ", $limits->maxipgroupmembers, " more IP groups members\n";
  # next bit isn't OO-ed yet.
  foreach my $k ( @{ $limits->rate } ) {
    print $k->{verb}, ' to URI ', $k->{URI}, ' remaining: ',
      $k->{remaining}, ' per ', $k->{unit},
      ' (will be reset at: ', scalar localtime $k->{resetTime}, ')',
      "\n";
  }

=head1 METHODS

=head2 new / BUILD

The constructor creates a Limits half-object. See L<refresh> to refresh the limits once gathered.

This normally gets created for you by L<Net::RackSpace::Cloudserver>'s L<limits> method.
Needs a Net::RackSpace::CloudServers object as B<cloudserver> parameter.

=head2 refresh

This method refreshes the information contained in the object

=head1 ATTRIBUTES

=head2 totalramsize

Indicates the maximum amount of RAM (in megabytes) linked to your account.

=head2 maxipgroups

Indicates the maximum number of shared IP groups your account can create

=head2 maxipgroupmembers

Indicates the maximum amount of servers that can be associated with any one shared IP group

=head2 rate

TODO: not yet OO-ified.

Is an arrayref of the rate-limits that currently apply to your account via the API.
You'll receive 413 errors in case you exceed the limits described.

=head1 AUTHOR

Marco Fontani, C<< <mfontani at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rackspace-cloudservers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-RackSpace-CloudServers>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::RackSpace::CloudServers::Limits

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-RackSpace-CloudServers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-RackSpace-CloudServers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-RackSpace-CloudServers>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-RackSpace-CloudServers/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Marco Fontani, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
