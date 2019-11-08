package Net::SecurityCenter::API;

use warnings;
use strict;

use Net::SecurityCenter::Error;

our $VERSION = '0.204';

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {

    my ( $class, $client ) = @_;

    my $self = {
        client => $client,
        _error => undef,
    };

    return bless $self, $class;

}

#-------------------------------------------------------------------------------

sub client {

    my ($self) = @_;
    return $self->{client};

}

#-------------------------------------------------------------------------------

sub error {

    my ( $self, $message, $code ) = @_;

    if ( defined $message ) {
        $self->{'client'}->{'_error'} = Net::SecurityCenter::Error->new( $message, $code );
        return;
    } else {
        return $self->{'client'}->{'_error'};
    }

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API - API Base Class for Net::Security::Center


=head1 SYNOPSIS

    use Net::SecurityCenter;

    my $sc = Net::SecurityCenter('sc.example.org');

    $sc->login('secman', 'password');

    $scan->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 METHODS


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
