package Opsview::REST::Config;
{
  $Opsview::REST::Config::VERSION = '0.013';
}

use Moo;
use Carp;

has base => (
    is       => 'ro',
    default  => sub { '/config/' },
    init_arg => undef,
);

with 'Opsview::REST::QueryBuilder';

has '+path' => (
    required => 1,
);

my @valid_types = qw/
    contact host role servicecheck hosttemplate attribute timeperiod hostgroup
    servicegroup notificationmethod hostcheckcommand keyword monitoringserver
/;

sub BUILDARGS {
    my ($class, $obj_type, @args) = @_;

    croak "object type required" unless $obj_type;

    my $id;
    $id = shift @args if (scalar @args & 1 == 1);
    croak "odd number of elements" if (scalar @args & 1 == 1);

    if (defined $id) {
        if ($id !~ /^\d+$/) {
            croak 'id must be numeric';
        }
    }

    if (defined $obj_type) {
        unless (scalar grep { $obj_type eq $_ } @valid_types) {
            croak 'object type must be one of: ' . join ' ', @valid_types;
        }
    } else {
        $obj_type = '';
    }

    if (@args == 1) {
        return {};
    } else {
        my $path = '';
        if ($obj_type) {
            $path = $obj_type;
            $path .= "/$id" if $id;
        }

        return {
            path => $path, 
            args => { @args },
        };
    }
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=pod

=head1 NAME

Opsview::REST::Config - Convenience object to transform its attributes into a /config URL endpoint

=head1 SYNOPSIS

    use Opsview::REST::Config;

    my $config = Opsview::REST::Config->new(
        'host',
        host => [qw/ hostA hostB /], 
    );
    $config->as_string; # '/config/host?host=hostA&host=hostB'

=head1 DESCRIPTION

You shouldn't be calling this directly, but be using the "config" method in L<Opsview::REST>.

=head1 AUTHOR

=over 4

=item *

Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
