package MsgPack::Decoder::Generator;
our $AUTHORITY = 'cpan:YANICK';
$MsgPack::Decoder::Generator::VERSION = '2.0.3';
use 5.10.0;

use strict;
use warnings;

use List::Util qw/ reduce /;
use Module::Runtime qw/ use_module /;

use Log::Any;

use Moose;

use MooseX::MungeHas 'is_ro';

use experimental 'signatures', 'postderef';

has log => sub { 
    my $class = ref shift;
    $class =~ s/MsgPack::Decoder::Generator:://;
    Log::Any->get_logger->clone( prefix => "[$class] ");
};

has bytes => (
    required => 1,
);

has buffer => (
    traits => [ 'String' ],
    is => 'rw',
    default => '',
    handles => {
        append_buffer => 'append',
        buffer_size   => 'length',
    },
    trigger => sub {
        my ( $self, $buffer ) = @_;

        return unless $self->can( 'gen_value' );

        return if length($buffer) < $self->bytes;

        $self->push_decoded->( $self->gen_value );
    },
);

has next => (
    is => 'ro',
    lazy => 1,
    builder => \&build_next,
    traits => [ 'Array' ],
    handles => {
        next_args => 'shift',
        push_next => 'push',
    },
);

sub build_next { [] }

sub BUILD { $_[0]->log->trace('generator created') }

sub buffer_as_int {
    my $self = shift;
    
    return reduce { ( $a << 8 ) + $b } map { ord } split '', $self->buffer;
}

has post_next => (
    is => 'ro',
    lazy => 1,
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        next_post_next => 'shift',
    },
);

has push_decoded => sub {
    return sub { };
};

sub next_read($self) {
    my $arg = $self->next_args || $self->next_post_next || [ 'Any' ];

    my( $class, @args ) = @$arg;

    $class = 'MsgPack::Decoder::Generator::' . $class;
    use_module($class)->new( 
        push_decoded => $self->push_decoded, 
        post_next    => [ $self->next->@*, $self->post_next->@* ],
        @args 
    );
}

use experimental 'current_sub';

sub read ( $self, $data ) {

    my $left_to_read = $self->bytes - $self->buffer_size;

    if ( $left_to_read > 0 ) {
        my $mine = substr $data, 0, $left_to_read, '';
        $self->log->trace( 'reading: ' . join ' ', map { sprintf "%#x", ord } split '', $mine );
        $self->append_buffer($mine);
        $left_to_read -= length $mine;

    }

    unless ( $left_to_read ) {
        @_ = ( $self->next_read, $data );
        goto __SUB__;
        #return $self->next_read->read($data);
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::Decoder::Generator

=head1 VERSION

version 2.0.3

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
