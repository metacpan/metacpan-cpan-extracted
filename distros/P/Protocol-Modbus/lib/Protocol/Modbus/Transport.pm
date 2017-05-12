package Protocol::Modbus::Transport;

use strict;
use warnings;
use Carp ();

sub new {
    my ($obj, %args) = @_;
    my $class = ref($obj) || $obj;
    my $self = {_options => {%args},};

    # If driver property specified, load "additional" modbus transport class (TCP / Serial)
    if (exists $args{driver} && $args{driver} ne '') {
        $class = "Protocol::Modbus::Transport::$args{driver}";
        eval "use $class";
        if ($@) {
            Carp::croak(
                "Protocol::Modbus::Transport driver `$args{driver}' failed to load: $@");
            return (undef);
        }
    }

    bless $self, $class;
}

sub options {
    my $self = $_[0];
    return $self->{_options};
}

#
# Transport virtual methods
#
sub _virtual {
    my ($meth) = @_;
    croak($meth . '() must be implemented by transport layer!');
    return undef;
}

sub connect {
    _virtual('connect');
}

sub disconnect {
    _virtual('disconnect');
}

sub send {
    _virtual('send');
}

sub receive {
    _virtual('receive');
}

1;

=head1 NAME

Protocol::Modbus::Transport - Modbus protocol transport layer base class

=head1 DESCRIPTION

Abstract class. No use unless it's derived.

=head1 METHODS

=over +

=item connect

=item disconnect

=item send

=item receive

=back

=head1 SEE ALSO

=over *

=item Protocol::Modbus

=back

=head1 AUTHOR

Cosimo Streppone, E<lt>cosimo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Cosimo Streppone

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
