package MooseX::Role::Net::OpenSSH;
use Moose::Role;
use namespace::clean -except => 'meta';
use Net::OpenSSH;
use Data::Dumper;

# ABSTRACT: A Moose role that provides a Net::OpenSSH Object
our $VERSION = '0.001'; # VERSION

has 'ssh' => (
    isa        => 'Net::OpenSSH',
    is         => 'ro',
    lazy_build => 1,
);

for my $name ( qw/ ssh_hostname ssh_username / ) {
    my $builder = '_build_' . $name;
    my $writer  = '_set_' . $name;
    has $name => (
        is         => 'ro',
        isa        => 'Str',
        builder    => $builder,
        writer     => $writer,
        lazy_build => 1,
    );
}

has 'ssh_options' => (
    isa        => 'HashRef',
    is         => 'ro',
    lazy_build => 1,
);

sub _build_ssh {
    my $self = shift;
    Net::OpenSSH->new( $self->ssh_hostname, %{ $self->ssh_options } );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Role::Net::OpenSSH - A Moose role that provides a Net::OpenSSH Object

=head1 VERSION

version 0.001

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/trcjr/MooseX-Role-Net-OpenSSH/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/trcjr/MooseX-Role-Net-OpenSSH>

  git clone https://github.com/trcjr/MooseX-Role-Net-OpenSSH.git

=head1 AUTHOR

Theodore Robert Campbell Jr <trcjr@cpan.org>

=head1 CONTRIBUTOR

Theodore Robert Campbell Jr <trcjr@stupidfoot.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Theodore Robert Campbell Jr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
