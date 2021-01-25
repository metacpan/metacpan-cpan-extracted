package Net::OpenVAS::Error;

use warnings;
use strict;

use overload q|""| => 'message', fallback => 1;

our $VERSION = '0.200';

#-------------------------------------------------------------------------------
# CONSTRUCTOR
#-------------------------------------------------------------------------------

sub new {

    my ( $class, $message, $code ) = @_;

    my $self = { message => $message, code => $code, caller => [ caller(1) ] };

    return bless $self, $class;

}

#-------------------------------------------------------------------------------

sub message {
    my ($self) = @_;
    return $self->{'message'};
}

#-------------------------------------------------------------------------------

sub code {
    my ($self) = @_;
    return $self->{'code'};
}

#-------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OpenVAS::Error - Error helper for Net::OpenVAS


=head1 SYNOPSIS

    use Net::OpenVAS;

    my $openvas = Net::OpenVAS->new(
        host     => 'localhost:9390',
        username => 'admin',
        password => 's3cr3t'
    ) or die "ERROR: $@";

    if ( $openvas->error ) {
        say "ERROR: " . $openvas->error;
    }


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-OpenVAS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-OpenVAS>

    git clone https://github.com/giterlizzi/perl-Net-OpenVAS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
