package Parallel::Workers::Backend;

use warnings;
use strict;
use Carp;
use Data::Dumper;

use Module::Pluggable
  search_path => [ "Parallel::Workers::Backend" ],
  sub_name    => 'backends';




# Module implementation here
# ( backend=> "SSH", contructor => $value)
sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};

    my ($backend) = $args{backend} || (grep !/::Null$/, $self->backends)[0];
    $backend ||= "Parallel::Workers::Backend::Null";

    eval "require $backend" or die $@;
    return unless $backend;
    $self->{backend} = $backend->new(%{$args{constructor}})  or return;
    
    bless $self, $class;
    return $self;
}


sub pre {
    my $self = shift;
    return $self->{backend}->pre( @_ );
}

sub do {
    my $self = shift;
    return $self->{backend}->do(@_);
}

sub post {
    my $self = shift;
    return $self->{backend}->post( @_ );
}



1; # Magic true value required at end of module
__END__

=head1 NAME

Parallel::Workers::Backend - The backend is a plugins mechanism to run the worker tasks. 
Default plugins are implemented for Eval (CODE), SSH and XMLRPC tasks. You can add your own plugin 
with module name Parallel::Backend::YourTaskModule


=head1 VERSION

This document describes Parallel::Workers::Backend version I<$VERSION>


=head1 SYNOPSIS

    use Parallel::Workers::Backend;
    
    my $worker=Parallel::Workers->new(backend=>"Eval");
    my $worker=Parallel::Workers->new(backend=>"SSH");
    my $worker=Parallel::Workers->new(backend=>"XMLRPC");
    my $worker=Parallel::Workers->new(backend=>"YourTaskModule");


=head1 DEPENDENCIES

Dependencies are used only if you load the backend.
require Net::SSH::Perl
require Frontier::Client;



=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-parallel-jobs-backend@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Olivier Evalet  C<< <evaleto@gelux.ch> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Olivier Evalet C<< <evaleto@gelux.ch> >>. All rights reserved.

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
