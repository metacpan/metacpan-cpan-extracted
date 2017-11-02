package Net::HTTP::Spore::Role::Middleware;
$Net::HTTP::Spore::Role::Middleware::VERSION = '0.09';
use Moose::Role;
use Class::Load;
use Scalar::Util qw/blessed/;

has middlewares => (
    is         => 'rw',
    isa        => 'ArrayRef',
    traits     => ['Array'],
    lazy       => 1,
    default    => sub { [] },
    auto_deref => 1,
    handles    => { _add_middleware => 'push', _filter_middlewares => 'grep' },
);

sub _load_middleware {
    my ( $self, $mw, $cond, @args ) = @_;

    Class::Load::load_class($mw) unless blessed($mw);

    my $code = $mw->wrap( $cond, @args );
    $self->_trace_msg('== enabling middleware %s', $mw);
    $self->_add_middleware($code);
}

sub _complete_mw_name {
    my ($self, $mw) = @_;

    if ($mw =~ /^\+/) {
        $mw =~ s/^\+//;
    }
    elsif ($mw !~ /Net\:\:HTTP\:\:Spore\:\:Middleware/) {
        $mw = "Net::HTTP::Spore::Middleware::".$mw;
    }

    return $mw;
}

sub enable {
    my ($self, $mw, @args) = @_;

    confess "middleware name is missing" unless $mw;

    $self->enable_if(sub{1}, $mw, @args);
    $self;
}

sub enable_if {
    my ($self, $cond, $mw, @args) = @_;

    confess "condition must be a code ref" if (!$cond || ref $cond ne 'CODE');

    if(ref($mw) eq 'CODE'){ # anonymous middleware
        Class::Load::load_class('Net::HTTP::Spore::Middleware');
        my $anon = Class::MOP::Class->create_anon_class(
            superclasses => ['Net::HTTP::Spore::Middleware'],
            methods => {
                call => $mw
            }
        );
        $mw = $anon->new_object;
    } else {
        $mw = $self->_complete_mw_name($mw);
    }
    $self->_load_middleware($mw, $cond, @args);
    $self;
}

sub reset_middlewares {
    my $self = shift;
    $self->middlewares([]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Role::Middleware

=head1 VERSION

version 0.09

=head1 AUTHORS

=over 4

=item *

Franck Cuny <franck.cuny@gmail.com>

=item *

Ash Berlin <ash@cpan.org>

=item *

Ahmad Fatoum <athreef@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
