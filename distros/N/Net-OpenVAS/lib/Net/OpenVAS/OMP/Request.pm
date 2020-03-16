package Net::OpenVAS::OMP::Request;

use strict;
use warnings;
use utf8;
use feature ':5.10';

use XML::Simple qw( :strict );

use overload q|""| => 'raw', fallback => 1;

our $VERSION = '0.100';

sub new {

    my ( $class, %args ) = @_;

    my $command   = $args{'command'};
    my $arguments = $args{'arguments'};

    my $request = { $command => $arguments };
    my $raw     = XMLout(
        $request,
        NoEscape      => 0,
        SuppressEmpty => 1,
        KeepRoot      => 1,
        KeyAttr       => $command
    );

    chomp($raw);

    my $self = {
        command   => $command,
        arguments => $arguments,
        raw       => $raw,
    };

    return bless $self, $class;

}

sub raw {
    my ($self) = @_;
    return $self->{raw};
}

sub command {
    my ($self) = @_;
    return $self->{command};
}

sub arguments {
    my ($self) = @_;
    return $self->{arguments};
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OpenVAS::OMP::Request - Helper class for Net::OpenVAS::OMP


=head1 SYNOPSIS

    use Net::OpenVAS::OMP::Request;

    my $request = Net::OpenVAS::OMP::Request->new(
        command   => 'create_task',
        arguments => { ... }
    );


=head1 CONSTRUCTOR

=head2 Net::OpenVAS::OMP::Request->new ( command => $command, arguments => \%arguments )

Create a new instance of L<Net::Net::OpenVAS::OMP::Response>.

Params:

=over 4

=item * C<command> : OMP command

=item * C<arguments> : Command argumments

=back


=head1 METHODS

=head2 $request->command

Return OMP command.

=head2 $request->arguments

Return OMP command arguments.

=head2 $request->raw

Return RAW OMP command.


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
