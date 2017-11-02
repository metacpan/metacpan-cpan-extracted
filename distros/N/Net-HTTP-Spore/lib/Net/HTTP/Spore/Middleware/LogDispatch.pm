package Net::HTTP::Spore::Middleware::LogDispatch;
$Net::HTTP::Spore::Middleware::LogDispatch::VERSION = '0.09';
# ABSTRACT: Net::HTTP::Spore::Middleware::LogDispatch is a middleware that allow you to use LogDispatch.

use Moose;
extends 'Net::HTTP::Spore::Middleware';

has logger => (is => 'rw', isa => 'Log::Dispatch', required => 1);

sub call {
    my ($self, $req) = @_;

    my $env = $req->env;
    $env->{'sporex.logger'} = sub {
        my $args = shift;
        $args->{level} = 'critical' if $args->{level} eq 'fatal';
        $self->logger->log(%$args);
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::HTTP::Spore::Middleware::LogDispatch - Net::HTTP::Spore::Middleware::LogDispatch is a middleware that allow you to use LogDispatch.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    my $log = Log::Dispatch->new();
    $log->add(
        Log::Dispatch::File->new(
            name      => 'file1',
            min_level => 'debug',
            filename  => 'logfile'
        )
    );

    my $client = Net::HTTP::Spore->new_from_spec('twitter.json');
    $client->enable( 'LogDispatch', logger => $log );

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
