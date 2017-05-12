package Net::DSLProvider;
use warnings;
use strict;
use base 'Class::Accessor';
use Carp qw/croak/;
our $VERSION = '0.03';
__PACKAGE__->mk_accessors(qw/user pass debug testing/);

=head1 NAME

Net::DSLProvider - Standardized interface to various DSL providers

=head1 SYNOPSIS

    use Net::DSLProvider;
    my $p = Net::DSLProvider::SomeISP->new(user => $u, pass => $p);
    ...

=head1 DESCRIPTION

This class doesn't do much - please see the individual
Net::DSLProvider::* modules instead.

=cut

my %sigs;

sub _check_params {
    my ($self, $args, @additional) = @_;
    my $method = ((caller(1))[3]);
    $method =~ s/.*:://;
    my @signature = @{$sigs{$method}} if $sigs{$method};
    for (@signature, @additional) {
        my $ok = 0;
        my @poss = split /\|/, $_; 
        for (@poss) { $ok=1 if $args->{$_} };
        croak "You must supply the $poss[0] parameter" if !$ok and @poss==1;
        croak "You must supply at least one of the following parameters: @poss" 
            if !$ok;
    }
}

=head1 METHODS
 
=head1 INFORMATIONAL METHODS
  
These methods tell you things.
  
=head2 services_available
    
Takes a phone number or a postcode and returns a list of services
that the provider can deliver to the given line.
     
Parameters:
      
    cli / postcode (Required)
    mac (Optional)
       
Output is an array of hash references. Each hash reference may contain
the following keys:
        
    first_date
    max_speed
    product_name
    product_id (Required)
         
=cut
          
$sigs{services_available} = ["cli|postcode"];

$sigs{verify_mac} = [qw/cli mac/];

$sigs{service_view} = ["ref|telephone|username|service-id"];
$sigs{service_details} = ["ref|telephone|username|service-id"];

$sigs{usage_summary} = [qw/year month/];

$sigs{auth_log} = ["ref|telephone|username|service-id"];


=head1 EXECUTIVE METHODS

These methods do things

=cut

$sigs{order} = [qw/prod-id forename surname street city postcode 
                   cli client-ref prod-id crd/]; 

$sigs{regrade} = ["ref|telephone|username|service-id", "prod-id"];

$sigs{care_level} = ["ref|telephone|username|service-id", "care-level"];

$sigs{request_mac} = ["ref|telephone|username|service-id"];

$sigs{cease} = ["ref|telephone|username|service-id", "crd"];

$sigs{change_password} = [qw/ref|telephone|username|service-id password/];

=head1 AUTHOR

Simon Cozens, C<< <simon at simon-cozens.org> >>
Jason Clifford C<< <jason at ukfsn.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-dslprovider at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-DSLProvider>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::DSLProvider


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-DSLProvider>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-DSLProvider>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-DSLProvider>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-DSLProvider/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to the UK Free Software Network (http://www.ukfsn.org/) for their
support of this module's development. For free-software-friendly hosting
and other Internet services, try UKFSN.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2012 Simon Cozens & Jason Clifford

This program is free software; you can redistribute it and/or modify it
under the terms of either: version 2 of the GNU General Public License 
as published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::DSLProvider
