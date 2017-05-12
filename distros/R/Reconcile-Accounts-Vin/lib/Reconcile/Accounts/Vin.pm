package Reconcile::Accounts::Vin;

use v5.14;
use Carp;

our $VERSION = 1.03;

sub new     
{
    my ($class) = shift;    
    my $self = {@_}; 
    $self->{checks} = [ \&_audit, \&_remove, \&_lpad ];
    $self->{entry} = 0;
    return bless $self, $class;
}

sub run_checks
{
	my ($self, $item) = @_;
	$item =~ s/(\w)/\U$1/gi;
	$self->{item} = $item;
	
    foreach my $method_name ( @{$self->{checks}} )
    {
        $method_name->($self);
    }

    return $self->{item};
}

sub _lpad
{
    my $self = shift;

    eval
    {	
		length($self->{item}) == $self->{length} && return;
		$self->{item} =~ s/(\w+)/sprintf "%017s",$1/ge;
    };	
    if ($@)	
    {
		carp "error in _lpad ";
    }    
}


sub _remove
{
    my $self = shift;
    
    eval
    {	
        $self->{item} =~ s/\W/\w/g;
		$self->{item} =~ s/$_/$self->{remove}->{$_}/gi for (keys %{$self->{remove}});
    };	
    if ($@)	
    {
		carp "error in _remove ";
    }   
}

sub _audit
{
    my $self = shift;
    eval
    {	
        $self->{entry}++;
    };	
    if ($@)	
    {
		carp "error in _audit ";
    }
}

sub get_length
{
    my $self = shift;
    return $self->{length} or carp "error in get_length ";
}

1; 


__END__

=head1 NAME

Vin - This performs basic data corrections to Vehicle Identification Numbers.
The main purpose of this module is to edit and return a string in a format more suited
for data parsers. This module may not return a valid VIN.

=head1 VERSION

1.01

This document describes Vin version 1.01

=head1 SYNOPSIS 

    use Vin;

    my $instance = Vin->new(length => 17, remove => {I => 1, O => 0, Q => 0},);

    $instance->get_length();	# return length of string
    $instance->run)checks();	# perform basic data corrections on the attribute and return it
   
=head1 DESCRIPTION

Vin does this:

=head2 get_length

get_length will return the length, 17 characters expected but not mandatory

=head2 run_checks 

run_checks will return a string corrected as per the attributes used in the
constructor.

=head1 VEHICLE IDENTIFICATION NUMBERS or VIN

A valid Australian VIN's must be uppercase and not contain I, O or Q. Any
occurrence of these will be changed to 0

=head1 METHODS

=head2 new()

Accepts an array of attributes - 
    length and value
    hashref of prohibited values / replacement values

=head2 get_length()

returns the length of the string being vaildated as a VIN

=head2 run_checks()

performs the task of transforming a string to comply with basic VIN standards

=head1 SEE ALSO

https://infrastructure.gov.au/vehicles/imports/vins.aspx

=head1 CONFIGURATION AND ENVIRONMENT

Vin requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS 

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-<RT NAME>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Vin


=head1 Paul Frazier

Paul Frazier  books.pandl@gmail.com

=head1 WARRANTY

None.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Paul Frazier books.pandl@gmail.com. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut


