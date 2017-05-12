package Plack::I18N::Util;

use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw(try_load_class);

use Plack::Util ();

sub try_load_class {
    my ($class) = @_;

    my $path = (join '/', split /::/, $class) . '.pm';

    return $class if exists $INC{$path} && defined $INC{$path};

    {
        no strict 'refs';
        for (keys %{"$class\::"}) {
            return $class if defined &{"$class\::$_"};
        }
    }

    eval {
        Plack::Util::load_class($class);
    } || do {
        my $e = $@;

        die $e unless $@ =~ m/Can't locate $path in \@INC/;

        return;
    };
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::I18N::Util - Module

=head1 SYNOPSIS



=head1 DESCRIPTION

Used internally.

=head1 ISA

L<Exporter>

=head1 METHODS

=head2 C<try_load_class($class)>

=head1 INHERITED METHODS

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
