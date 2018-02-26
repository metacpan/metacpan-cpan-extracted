package Pcore::HTTP::Response;

use Pcore -class;
use Pcore::HTTP::Headers;
use Pcore::Util::Scalar qw[is_plain_coderef is_plain_scalarref];

with qw[Pcore::Util::Result::Status];

has url => ( is => 'ro', isa => Str | Object );
has buf_size => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );    # write body to fh if body length > this value, 0 - always store in memory, 1 - always store to file

has version => ( is => 'ro', isa => Num, init_arg => undef );
has headers => ( is => 'ro', isa => InstanceOf ['Pcore::HTTP::Headers'], init_arg => undef );
has body    => ( is => 'ro', isa => Ref,                                 init_arg => undef );
has path    => ( is => 'ro', isa => Str,                                 init_arg => undef );

has content_length => ( is => 'rwp', isa => PositiveOrZeroInt, default => 0, init_arg => undef );

has redirect => ( is => 'ro', isa => ArrayRef, init_arg => undef );
has decoded_body => ( is => 'lazy', isa => Maybe [ScalarRef], init_arg => undef );
has is_connect_error => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );
has tree => ( is => 'lazy', isa => Maybe [ InstanceOf ['HTML::TreeBuilder::LibXML'] ], init_arg => undef );

sub BUILD ( $self, $args ) {
    $self->{headers} = Pcore::HTTP::Headers->new;

    $self->{headers}->add( $args->{headers} ) if $args->{headers};

    $self->{body} = $args->{body} if $args->{body};

    return;
}

sub _build_decoded_body ($self) {
    return if !$self->{body};

    return if !is_plain_scalarref $self->{body};

    state $init = !!require HTTP::Message;

    return HTTP::Message->new( [ 'Content-Type' => $self->{headers}->{CONTENT_TYPE} ], $self->{body}->$* )->decoded_content( raise_error => 1, ref => 1 );
}

sub _build_tree ($self) {
    return if !$self->{body};

    return if !is_plain_scalarref $self->{body};

    state $init = !!require HTML::TreeBuilder::LibXML;

    my $tree = HTML::TreeBuilder::LibXML->new;

    $tree->parse( $self->decoded_body->$* );

    $tree->eof;

    return $tree;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::HTTP::Response

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
