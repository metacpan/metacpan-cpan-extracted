package Net::Analysis::Listener::Example1;
# $Id: Example1.pm 140 2005-10-21 16:31:29Z abworrall $

use strict;
use warnings;
use base qw(Net::Analysis::Listener::Base);

sub tcp_monologue {
    my ($self, $args) = @_;
    my ($mono) = $args->{monologue}; # isa Net::Analysis::TCPMonologue

    my $t = $mono->t_elapsed()->as_number();
    my $l = $mono->length();

    $self->emit(name => 'example_bandwidth_measurement_event',
                args => { kb_sec => ($t) ? $l/($t*1024) : 0 }
               );
}

sub example_bandwidth_measurement_event {
    my ($self, $args) = @_;

    printf "Bandwidth: %10.2f KB/sec\n", $args->{kb_sec};
}

1;

__END__

=head1 NAME

Net::Analysis::Listener::Example1 - emit/receive custom events

=head1 SYNOPSIS

 package Net::Analysis::Listener::Example1;

 use strict;
 use warnings;
 use base qw(Net::Analysis::Listener::Base);

 sub tcp_monologue {
     my ($self, $args) = @_;
     my ($mono) = $args->{monologue}; # isa Net::Analysis::TCPMonologue

     my $t = $mono->t_elapsed()->as_number();
     my $l = $mono->length();

     $self->emit(name => 'example_bandwidth_measurement_event',
                 args => { kb_sec => ($t) ? $l/($t*1024) : 0 }
                );
 }

 sub example_bandwidth_measurement_event {
     my ($self, $args) = @_;

     printf "Bandwidth: %10.2f KB/sec\n", $args->{kb_sec};
 }

 1;

You can invoke this example on a TCP capture file from the command line, as
follows:

 $ perl -MNet::Analysis -e main Example1 t/t1_google.tcp

=head1 DESCRIPTION

This example shows how to emit your own custom events, and also how to listen
to them. This particular example has C<example_bandwidth_measurement_event> in
the same Listener.pm file, but you could easily put it in another Listener.pm
if you wanted - just remember to tell the dispatcher about both of them.

=head1 SEE ALSO

L<Net::Analysis>.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
