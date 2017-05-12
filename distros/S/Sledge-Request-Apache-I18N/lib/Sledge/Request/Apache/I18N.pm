package Sledge::Request::Apache::I18N;
use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(req));

use vars qw($AUTOLOAD);
use Sledge::Request::Apache::I18N::Upload;
use Apache::Request;
use Encode;

sub new {
    my($class, $r) = @_;
    bless { req => Apache::Request->new($r) }, $class;
}

sub upload {
    my $self = shift;
    Sledge::Request::Apache::I18N::Upload->new($self, @_);
}

sub param {
    my $self = shift;
    if ( @_ == 0) {
        return map { $self->_decode_param($_) } $self->req->param;
    } elsif ( @_ == 1) {
        my @value = map { $self->_decode_param($_) } $self->req->param($_[0]);
        return wantarray ? @value : $value[0];
    } else {
        my ($key, $param) = @_;
        if (ref $param eq 'ARRAY') {
            $param = [map { $self->_encode_param($_) } @$param];
            return $self->req->param( $key, $param);
        } elsif ( ! ref $param ) {
            return $self->req->param($_[0], $self->_encode_param($_[1]));
        } else {
            return $self->req->param(@_);
        }
    }
}

sub _decode_param {
    my ($self, $val) = @_;
    return Encode::is_utf8($val)
           ? $val
           : Encode::decode('utf-8', $val);
}

sub _encode_param {
    my ($self, $val) = @_;
    return Encode::is_utf8($val)
           ? Encode::encode('utf-8', $val)
           : $val;
}

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    $self->req->$meth(@_);
}

1;

__END__

=head1 NAME

Sledge::Request::Apache::I18N -

=head1 SYNOPSIS

  use Sledge::Request::Apache::I18N;

=head1 DESCRIPTION

Sledge::Request::Apache::I18N is

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<>

=cut
