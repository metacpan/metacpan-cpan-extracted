package RT::Extension::Converter::RT1::Config;
use base qw/RT::Extension::Converter::Config/;
use warnings;
use strict;

__PACKAGE__->mk_accessors(qw(dbuser dbpassword database dbhost data_directory 
                             email_domain ));

=head1 NAME

RT::Extension::Converter::RT1::Config - config data for the RT1 importer


=head1 SYNOPSIS

    use RT::Extension::Converter::RT1::Config;
    
Usually retrieved from a converter object with

    $rt1converter->config

=head1 DESCRIPTION

Useful config values for the RT1 converter.
These include where to find rt data, how to log into the rt1 database, and some
sane defaults about where to store tickets in the RT3 system

=head1 METHODS

=head2 dbuser

user for the rt1 database

=head2 dbpassword

password for the rt1 database

=head2 database

name of the rt1 database

=head2 dbhost

host for the rt1 database

=head2 data_directory

where to find the rt1 transaction files

=head2 email_domain

users without emails will have emails autocreated like this

 user_id@email_domain

=head2 new

creates an RT1 config object and sets some defaults 
carried over from the old rt1 import script

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->dbuser("root");
    $self->dbpassword("password");
    $self->database("rt");
    $self->dbhost("localhost");
    $self->data_directory("/opr/rt/transactions");
    $self->email_domain("example.com");

    return $self;
}

=head1 AUTHOR

Kevin Falcone  C<< <falcone@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Best Practical Solutions, LLC.  All rights reserved.

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

1;

