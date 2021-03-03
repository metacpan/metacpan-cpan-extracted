package Net::SecurityCenter::Error;

use warnings;
use strict;

use overload q|""| => 'message', fallback => 1;

our $VERSION = '0.310';

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {

    my ( $class, $message, $code ) = @_;

    my $self = {
        message => $message,
        code    => $code,
    };

    return bless $self, $class;

}

#-------------------------------------------------------------------------------

sub message {
    return shift->{message};
}

#-------------------------------------------------------------------------------

sub code {
    return shift->{code};
}

#-------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SecurityCenter::Error - Error helper for Net::SecurityCenter


=head1 SYNOPSIS

    use Net::SecurityCenter;

    my $sc = Net::SecurityCenter('sc.example.org');

    $sc->login('secman', 'password') or die $sc->error;

    if ($sc->error) {
        die $sc->error;
    }

    my $res = $sc->scan_result->list;

    if (my $error = $sc->error) {
        die $error;
    }

    $sc->logout();


=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::Error->new ( $message [, $code ] )

Create a new instance of L<Net::SecurityCenter::Error>.


=head1 METHODS

=head2 $error->message

Return the error message.

=head2 $error->code

Return the error code.

=head1 ERROR HANDLING

Detect undef result:

    $sc->get('/scanResult') or die $sc->error;

    # or

    my $res = $sc->get('/scanResult/1337');

    if (! $res) {
        die $sc->error;
    }

Use error object:

    my $res = $sc->get('/scanResult/1337');

    if (my $error = $sc->error) {
        die $error;
    }

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

This software is copyright (c) 2018-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
