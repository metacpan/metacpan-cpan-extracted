package Pcore::Core::Exception::Object;

use Pcore -class;
use Pcore::Util::Scalar qw[blessed];
use Time::HiRes qw[];

use overload    #
  q[""] => sub {

    # string overloading can happens only from perl internals calls, such as eval in "use" or "require" (or other compilation errors), or not handled "die", so we don't need full trace here
    return $_[0]->{msg} . $LF;
  },
  q[0+] => sub {
    return $_[0]->exit_code;
  },
  bool => sub {
    return 1;
  },
  fallback => undef;

has msg => ( is => 'ro', isa => Str, required => 1 );
has level => ( is => 'ro', isa => Enum [qw[ERROR WARN]], required => 1 );
has call_stack => ( is => 'ro', isa => Maybe [ScalarRef], required => 1 );
has timestamp => ( is => 'ro', isa => Num, required => 1 );

has exit_code      => ( is => 'lazy', isa => Int );
has with_trace     => ( is => 'ro',   isa => Bool, default => 1 );
has is_ae_cb_error => ( is => 'ro',   isa => Bool, required => 1 );

has longmess  => ( is => 'lazy', isa => Str, init_arg => undef );
has to_string => ( is => 'lazy', isa => Str, init_arg => undef );

has is_logged => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );

around new => sub ( $orig, $self, $msg, %args ) {
    $args{skip_frames} //= 0;

    if ( my $blessed = blessed $msg ) {

        # already cought
        if ( $blessed eq __PACKAGE__ ) {
            return $msg;
        }

        # catch TypeTiny exceptions
        elsif ( $blessed eq 'Error::TypeTiny::Assertion' ) {
            $msg = $msg->message;

            # skip frames: Error::TypeTiny::throw
            $args{skip_frames} += 1;
        }

        # catch Moose exceptions
        elsif ( $blessed =~ /\AMoose::Exception/sm ) {
            $msg = $msg->message;
        }

        # other foreign exception objects are returned as-is
        # else {
        #     return;
        # }
    }

    # cut trailing "\n" from $msg
    {
        local $/ = q[];

        chomp $msg;
    };

    \my $is_ae_cb_error = \$args{is_ae_cb_error};

    my $x = $args{skip_frames} + 3;

    my @frames;

    while ( my @frame = caller $x++ ) {
        push @frames, "$frame[3] at $frame[1] line $frame[2]";

        # detect AnyEvent error in callback
        if ( !defined $is_ae_cb_error ) {
            if ( $frame[3] eq '(eval)' ) {
                if ( $frame[0] eq 'AnyEvent::Impl::EV' ) {
                    $is_ae_cb_error = 1;
                }
                else {
                    $is_ae_cb_error = 0;
                }
            }
        }
    }

    $args{call_stack} = \join $LF, @frames;

    $args{timestamp} = Time::HiRes::time();

    # stringify $msg
    $args{msg} = "$msg";

    # $args{msg} = "AE: error in callback: $args{msg}" if $is_ae_cb_error;

    return bless \%args, $self;
};

# CLASS METHODS
sub PROPAGATE ( $self, $file, $line ) {
    return $self;
}

sub _build_exit_code ($self) {

    # return $! if $!;              # errno
    # return $? >> 8 if $? >> 8;    # child exit status
    return 255;    # last resort
}

sub _build_longmess ($self) {
    if ( $self->{call_stack}->@* ) {
        return $self->{msg} . $LF . $self->{call_stack}->$*;
    }
    else {
        return $self->{msg};
    }
}

sub _build_to_string ($self) {
    return $self->{with_trace} ? $self->longmess : $self->{msg};
}

sub sendlog ( $self, $level = undef ) {
    return if $self->{is_logged};    # prevent logging the same exception twice

    $level //= $self->{level};

    $self->{is_logged} = 1;

    P->sendlog( "EXCEPTION.$level", $self->{msg}, $self->{with_trace} ? $self->{call_stack}->$* : undef );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Exception::Object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
