package Resque::Plugin;
# ABSTRACT: Syntactic sugar for Resque plugin's
$Resque::Plugin::VERSION = '0.31';
use Moose();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => ['add_to'],
    also      => 'Moose',
);

sub add_to {
    my ( $meta, $to, @options ) = @_;
    return unless @options;

    die "Can't add roles to '$to'. Only 'resque', 'worker' and 'job' are allowed!\n" 
        unless $to =~ /^(?:resque|worker|job)$/;

    $meta->add_attribute( "${to}_roles", is => 'ro', default => _build_default( @options ) );
}

sub _build_default {
    my $opt = @_ == 1 && ref $_[0] ? $_[0] : [@_];
    return sub { $opt };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Resque::Plugin - Syntactic sugar for Resque plugin's

=head1 VERSION

version 0.31

=head1 METHODS

=head2 add_to

Role applier for Resque, Resque::Worker and Resque::Job.

=head1 AUTHOR

Diego Kuperman <diego@freekeylabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Diego Kuperman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
