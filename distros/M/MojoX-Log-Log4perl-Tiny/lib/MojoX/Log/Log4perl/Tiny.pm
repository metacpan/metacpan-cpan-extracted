package MojoX::Log::Log4perl::Tiny;
use Mojo::Base -base;

our $VERSION = "0.01";

has 'logger';
has level            => 'debug';
has max_history_size => 5;
has history          => sub { [] };
has format           => sub {
    sub {
        '[' . localtime(shift) . '] [' . shift() . '] ' . join "\n", @_, '';
    };
};

my %LEVEL = (
    debug => 1,
    info  => 2,
    warn  => 3,
    error => 4,
    fatal => 5,
);

{
    no strict 'refs';
    for my $level (keys %LEVEL) {
        *$level = sub {
            my $self = shift;
            return if not $self->is_level($level);

            my $history = $self->history;
            my $max     = $self->max_history_size;

            push @$history, [ time, $level, @_ ];
            shift @$history while @$history > $max;

            local $Log::Log4perl::caller_depth = 1;
            $self->logger->$level(@_);
        };
    }
}

sub is_level {
    my ($self, $level) = @_;
    $LEVEL{$level} >= $LEVEL{ $ENV{MOJO_LOG_LEVEL} || $self->level };
}

1;
__END__

=encoding utf-8

=head1 NAME

MojoX::Log::Log4perl::Tiny - Minimalistic Log4perl adapter for Mojolicious

=head1 SYNOPSIS

    use MojoX::Log::Log4perl::Tiny;

    # In your $app->setup...

    $app->log(
        MojoX::Log::Log4perl::Tiny->new(
            logger => Log::Log4perl->get_logger('MyLogger')
        )
    );

=head1 DESCRIPTION

MojoX::Log::Log4perl::Tiny allows you to replace default Mojolicious logging C<Mojo::Log> with
your existing C<Log::Log4perl::Logger> instance.

=head1 METHODS

=head2 new(Hash %args) returns MojoX::Log::Log4perl::Tiny

Creates and returns an instance to replace C<Mojolicious-&gt;log>.

=over 4

=item * logger

A C<Log::Log4perl::Logger> instance. B<Required>.

=item * level

Minimum log level for logging.  Default: "debug"

=item * max_history_size

Max history size for logs to be shown on "exception.html.ep".  Default: 5

=back

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.orgE<gt>

=cut

