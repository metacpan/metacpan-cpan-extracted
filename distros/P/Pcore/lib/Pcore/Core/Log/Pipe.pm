package Pcore::Core::Log::Pipe;

use Pcore -class;
use Pcore::Util::Text qw[encode_utf8 remove_ansi];

has uri => ( is => 'ro', isa => InstanceOf ['Pcore::Util::URI'], required => 1 );

has id           => ( is => 'lazy', isa => Str,         init_arg => undef );
has priority     => ( is => 'lazy', isa => PositiveInt, init_arg => undef );
has is_text      => ( is => 'lazy', isa => Bool,        init_arg => undef );
has is_text_ansi => ( is => 'lazy', isa => Bool,        init_arg => undef );
has is_binary    => ( is => 'lazy', isa => Bool,        init_arg => undef );
has data_type    => ( is => 'lazy', isa => Str,         init_arg => undef );

sub _build_id ($self) {
    return $self->uri->to_string;
}

sub _build_priority ($self) {
    return 10;
}

sub _build_is_text ($self) {
    return 1;
}

sub _build_is_text_ansi ($self) {
    return 0;
}

sub _build_is_binary ($self) {
    return !$self->is_text;
}

sub _build_data_type ($self) {
    return join q[], $self->is_text, $self->is_text_ansi, $self->is_binary;
}

# MUST be redefined
sub sendlog ( $self, $header, $data, $tag ) {
    die q["sendlog" method is not implemented];
}

sub prepare_data ( $self, $data ) {
    encode_utf8($data) if $self->is_binary;

    remove_ansi($data) if !$self->is_text_ansi;

    return $data;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Log::Pipe

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
