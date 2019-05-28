package Pcore::API::AntiCaptcha::Role;

use Pcore -role;

requires qw[resolve report_invalid];

has _queue => sub { {} };

around resolve => sub ( $orig, $self, $captcha, $cb = undef ) {
    return $cb ? $cb->($captcha) : $captcha if $captcha->{is_finished};

    return $self->$orig( $captcha, $cb );
};

around report_invalid => sub ( $orig, $self, $captcha ) {
    return if !$self->{is_finished} || $self->{is_reported};

    return $self->$orig($captcha);
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::AntiCaptcha::Role

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
