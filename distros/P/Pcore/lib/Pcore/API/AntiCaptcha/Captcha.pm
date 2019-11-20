package Pcore::API::AntiCaptcha::Captcha;

use Pcore -class, -res;

with qw[Pcore::Lib::Result::Role];

has api    => ( required => 1 );
has params => ( required => 1 );    # initial captcha params

has data     => ( init_arg => undef );
has solution => ( init_arg => undef );    # additional resolve info

sub solve ($self) {
    my $res = $self->{api}->solve($self);

    $self->@{qw[status reason data solution]} = $res->@{qw[status reason data solution]};

    return $self;
}

sub report ($self) {
    return $self->{api}->report($self);
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::AntiCaptcha::Captcha

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
