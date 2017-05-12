package Net::Social;

use strict;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
use base qw(Exporter);
use Module::Pluggable search_path => 'Net::Social::Service', 
                      sub_name    => '_fetch_services',
                      instantiate => 'new';



# relationship constants
use constant NONE        => 0x0;
use constant FRIENDED    => 0x1;
use constant FRIENDED_BY => 0x2;
use constant MUTUAL      => 0x3; # not strictly needed but convenient

@EXPORT_OK   = qw(NONE FRIENDED FRIENDED_BY MUTUAL);
%EXPORT_TAGS = ( all => [@EXPORT_OK] ); 
$VERSION     = 0.4;


=head1 NAME

Net::Social - abstracted interface for social networks

=head1 SYNOPSIS

    use Net::Social qw(:all); # get constants

    # What services are available
    my @services = Net::Social->services;

    # Fetch a handler for a service
    my $service = Net::Social->service('LiveJournal');

    # what fields are needed to login
    my %params = $service->params;

    foreach my $type (keys %params) {
        print "To $type:\n"; # either read or write
        foreach my $p (keys %$types{$type}) {
            print $params{$type}->{$p}->{name}." : ".$params{$type}->{$p}->{description}."\n";
            # also 'required' and 'sensitive'
        }
    }

    # login - my_params must have the required fields from %params
    $service->login(%my_params);

    # now fetch your friends
    my @friends  = $service->friends;

    # add a friend
    $service->add_friend($friend);
    
    # remove a friend
    $service->remove_friend($friend);
    

=head1 CONSTANTS

Optionally exports the constants 

    NONE
    FRIENDED
    FRIENDED_BY
    MUTUAL

Which describe the type of relationship with a friend.

It should be noted that 

    MUTUAL = FRIENDED | FRIENDED_BY;

but is provided for convenience.

=head1 METHODS

=cut

sub _services {
    my $class  = shift;
    my %services;
    for my $service ($class->_fetch_services) {
        my $name = ref($service);
        $name    =~ s!^Net::Social::Service::!!;
        next if $name =~ m!::!;
        $services{lc($name)} = $service;
    }
    return %services;
}
=head2 services

A list of all services available.

=cut

sub services {
    my $class = shift;
    my %services = $class->_services();
    return keys %services;
}


=head2 service <service name>

Fetch the class for a given service

Returns undef if that service isn't found.

=cut

sub service {
    my $class    = shift;
    my $service  = shift;
    my %services = $class->_services();
    return $services{lc($service)};

}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright, 2007 - Simon Wistow

Distributed under the same terms as Perl itself

=cut
