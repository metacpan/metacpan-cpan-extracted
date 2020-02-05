package Net::SecurityCenter::API::File;

use warnings;
use strict;

use Carp;

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.205';

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub upload {

    my ( $self, $file ) = @_;

    ( @_ == 2 ) or croak( 'Usage: ' . __PACKAGE__ . '->upload( $FILE )' );

    my $response = $self->client->upload($file);

    return if ( !$response );
    return $response->{filename};

}

#-------------------------------------------------------------------------------

sub clear {

    my ( $self, $file ) = @_;

    ( @_ == 2 ) or croak( 'Usage: ' . __PACKAGE__ . '->clear( $FILE )' );

    my $response = $self->client->post( '/file/clear', { filename => $file } );

    return if ( !$response );
    return 1;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::File - Perl interface to Tenable.sc (SecurityCenter) File REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::File;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::File->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the File REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::File->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::File> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 upload

Uploads a File.

    $sc->file->upload('/tmp/all-2.0.tar.gz');

=head2 clear

Removes the File associated with C<filename>.

    $sc->file->clear('4fk1r0');


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2019 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
