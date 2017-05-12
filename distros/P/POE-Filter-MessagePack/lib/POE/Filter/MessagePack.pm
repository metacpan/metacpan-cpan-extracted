package POE::Filter::MessagePack;
$POE::Filter::MessagePack::VERSION = '1.170412';
# ABSTRACT: A dead-simple POE::Filter for MessagePack
use strict;
use warnings;

use Data::MessagePack;
use Data::MessagePack::Stream;
use POE::Filter;

use vars qw($VERSION @ISA);
$VERSION = '1.001';
@ISA     = qw(POE::Filter);

sub MP ()     { 0 }
sub STREAM () { 1 }

sub new {
    my $type      = shift;
    my $mp        = Data::MessagePack->new;
    my $mp_stream = Data::MessagePack::Stream->new;

    my %opts = @_;

    $mp->prefer_integer if $opts{prefer_integer};
    $mp->canonical      if $opts{canonical};
    $mp->utf8           if $opts{utf8};

    my $self = bless [ $mp, $mp_stream ], $type;
    $self;
}

sub get {
    my ( $self, $chunks ) = @_;
    my @ret;
    push @ret, $self->[STREAM]->data while $self->[STREAM]->next;
    return \@ret;
}

sub get_one_start {
    my ( $self, $stream ) = @_;
    $self->[STREAM]->feed( join '', @$stream );
}

sub get_one {
    my $self = shift;
    my $obj  = $self->[STREAM]->next;
    return $obj ? [ $self->[STREAM]->data ] : [];
}

sub put {
    my ( $self, $chunks ) = @_;
    [ map { $self->[MP]->pack($_) } @$chunks ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Filter::MessagePack - A dead-simple POE::Filter for MessagePack

=head1 VERSION

version 1.170412

=head1 SYNOPSIS

    use POE::Filter::MessagePack;

    # Standalone example
    my $filter = POE::Filter::MessagePack->new;
    my $obj = { a => 1, b => 2 };
    my $packed = $filter->put([ $obj ])
    my $obj_array = $filter->get($packed);

    # Or with POE
    my $wheel = POE::Wheel::ReadWrite->new(
        Filter => POE::Filter::MessagePack->new,
        ...,
    );

=head1 DESCRIPTION

    This is a POE filter for MessagePacked data. Do not stack this with
    POE::Filter::Line, as MessagePack data is not line-oriented.

=head1 AUTHOR

Nick Shipp <nick@shipp.ninja>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nick Shipp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
