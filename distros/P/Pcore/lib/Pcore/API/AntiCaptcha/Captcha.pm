package Pcore::API::AntiCaptcha::Captcha;

use Pcore -class, -res;
use Pcore::Lib::Scalar qw[weaken];

# use overload
#   bool     => sub { ( $_[0]->{is_finished} // 0 ) && ( $_[0]->{is_resolved} // 0 ) },
#   fallback => 1;

with qw[Pcore::Lib::Result::Role];

has api    => ( required => 1 );
has params => ( required => 1 );    # initial captcha params

has info => ( init_arg => undef );  # additional resolve info

has is_resolving   => ( init_arg => undef );
has is_resolved    => ( init_arg => undef );
has resolve_error  => ( init_arg => undef );
has _resolve_queue => ( init_arg => undef );

has is_verifying  => ( init_arg => undef );
has is_verified   => ( init_arg => undef );
has _verify_queue => ( init_arg => undef );

has is_reporting => ( init_arg => undef );
has is_reported  => ( init_arg => undef );

sub verify ( $self, $cb ) {

    # already verified
    return $self if $self->{is_verified};

    if ( $self->{is_verifying} ) {
        my $cv = P->cv;

        push $self->{_verify_queue}->@*, $cv;

        $cv->recv;

        return $self;
    }

    # start verufy captcha
    $self->{is_verifying} = 1;

    # resolve captcha, if is not resolved
    $self->resolve if !$self->{is_resoled};

    # captcha resolved with errors
    goto VERIFIED if !$self;

    # verify
    $self->set_status( $cb->($self) );

  VERIFIED:
    $self->{is_verifying} = 0;
    $self->{is_verified}  = 1;

    $self->report if !$self;

    while ( my $cb = shift $self->{_verify_queue}->@* ) {
        $cb->();
    }

    return $self;
}

sub resolve ($self) {
    return $self if $self->{is_resolved};

    if ( $self->{is_resolving} ) {
        my $cv = P->cv;

        push $self->{_resolve_queue}->@*, $cv;

        $cv->recv;

        return $self;
    }

    $self->{is_resolving} = 1;

    my $res = $self->{api}->resolve($self);

    $self->set_status($res);
    $self->{data} = $res->{data};
    $self->{info} = $res->{info};

    $self->{is_resolving}  = 0;
    $self->{is_resolved}   = 1;
    $self->{resolve_error} = 1 if !$res;

    while ( my $cb = shift $self->{_resolve_queue}->@* ) {
        $cb->();
    }

    return $self;
}

sub report ($self) {

    # can't report if resolved with error
    return res 200 if $self->{resolve_error};

    # can't report not verified captcha
    return res 200 if !$self->{is_verified};

    # already reporting
    return res 200 if $self->{is_reporting};

    # already reported
    return res 200 if $self->{is_reported};

    # do not report successfully verified captcha
    return res 200 if $self;

    $self->{is_reporting} = 1;

    my $res = $self->{api}->report($self);

    $self->{is_reporting} = 0;

    $self->{is_reported} = 1 if $res;

    return $res;
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
