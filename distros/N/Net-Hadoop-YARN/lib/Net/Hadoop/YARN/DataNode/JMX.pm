package Net::Hadoop::YARN::DataNode::JMX;
$Net::Hadoop::YARN::DataNode::JMX::VERSION = '0.203';
use 5.10.0;
use strict;
use warnings;

use Moo;

my $RE_PATH_KEY = qr{ Class[.]?Path }xmsi;

sub java_runtime {
    my $self = shift;
    my $run  = $self->collect( ['java.lang:type=Runtime'] ) || die "failed to collect Java runtime stats";
    my $bean = $run->{java}{lang}{type}{Runtime}{beans}[0]  || die "failed to collect Java runtime stats*";
    my $sys = $bean->{SystemProperties} = {
        map { $_->{key} => $_->{value} }
        @{ $bean->{SystemProperties } }
    };

    my $sep = quotemeta $sys->{'path.separator'};

    foreach my $path ( grep { $_ =~ $RE_PATH_KEY } keys %{ $sys } ) {
        $sys->{ $path } = [ split $sep, $sys->{ $path } ];
    }

    foreach my $path ( grep { $_ =~ $RE_PATH_KEY } keys %{ $bean } ) {
        $bean->{ $path } = [ split $sep, $bean->{ $path } ];
    }

    return $bean;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Hadoop::YARN::DataNode::JMX

=head1 VERSION

version 0.203

=head1 SYNOPSIS

    my $dn = Net::Hadoop::YARN::DataNode::JMX->new( %opt );

=head1 DESCRIPTION

YARN DataNode JMX methods.

=head1 METHODS

=head2 java_runtime

    my $java = $dn->java_runtime;

=head1 AUTHOR

David Morel <david.morel@amakuru.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by David Morel & Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
