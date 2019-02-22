use strict;
use warnings;
package String::ShortHostname;

# ABSTRACT: extracts the first field from an FQDN

use Moose;
use Moose::Exporter;
use 5.10.0;


Moose::Exporter->setup_import_methods( as_is => [ 'short_hostname' ]);

has 'hostname' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => '',
    predicate => 'has_hostname',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( hostname => short_hostname($_[0]) );
    }
    else {
        return $class->$orig(@_);
    }
};

around 'hostname' => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() unless @_;

    return $self->$orig( short_hostname( shift ) );
};

sub short_hostname {
    my $hostname = shift;
    my @bits;
    @bits = split /\./, $hostname if $hostname;
    my $alpha_found;
    for( @bits ){
        $alpha_found = 1 if /\D/;
    }
    if( $alpha_found ){
        return $bits[0];
    } else {
        return $hostname; # probably an IP Address
    }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::ShortHostname - extracts the first field from an FQDN

=head1 VERSION

version 1.000

=head1 SYNOPSIS

This module will take a fully qualified domain name and return the first field which is normally the
short hostname (mostly equivalent to C<hostname -s> on Linux).

    use String::ShortHostname;
    my $fqdn = 'testhost.example.com';
    my $hostname = short_hostname( $fqdn );
    print $hostname; 
    # prints 'testhost'

If an IPv4 address is passed to it, it will be returned verbatim. Otherwise the logic is simply to 
return everything before the first C<.>.

Alternatively, it can be used in an OO way, but without much benefit:

    use String::ShortHostname;
    my $fqdn = 'testhost.example.com';
    my $short = String::ShortHostname->new( $fqdn );
    my $hostname = $short->hostname;
    print $hostname; 
    # prints 'testhost'

=head1 BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
L<https://github.com/Q-Technologies/perl-String-ShortHostname>. Ideally, submit a Pull Request.

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
