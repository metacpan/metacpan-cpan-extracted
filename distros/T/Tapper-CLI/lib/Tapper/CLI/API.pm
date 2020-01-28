package Tapper::CLI::API;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::CLI::API::VERSION = '5.0.6';
use strict;
use warnings;

use parent 'App::Cmd';
use Tapper::Model 'model';

sub opt_spec
{
        my ( $class, $app ) = @_;

        return (
                [ 'help' => "This usage screen" ],
                $class->options($app),
               );
}

sub validate_args
{
        my ( $self, $opt, $args ) = @_;

        die $self->_usage_text if $opt->{help};
        $self->validate( $opt, $args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::CLI::API

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
