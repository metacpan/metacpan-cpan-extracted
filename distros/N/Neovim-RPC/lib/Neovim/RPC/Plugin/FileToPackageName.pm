package Neovim::RPC::Plugin::FileToPackageName;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: turns a path into a package name
$Neovim::RPC::Plugin::FileToPackageName::VERSION = '1.0.1';
use 5.20.0;

use strict;
use warnings;

use Neovim::RPC::Plugin;

use experimental 'signatures';

sub file_to_package_name {
    shift
    =~ s#^(.*/)?lib/##r
    =~ s#^/##r
    =~ s#/#::#rg
    =~ s#\.p[ml]$##r;
}

sub shall_get_filename ($self) {
    $self->api->vim_call_function( fname => 'expand', args => [ '%:p' ] );
}

subscribe file_to_package_name => rpcrequest 
    sub($self,@) {
        collect_props(
            filename => $self->shall_get_filename,
            line     => $self->api->vim_get_current_line,
        )
    },
    sub ($self,$props) {
        $self->api->vim_set_current_line(
            $props->{line} =~ s/__PACKAGE__/file_to_package_name($props->{filename})/er
        )
    };


sub collect_props {

    use Promises qw/ deferred /;
    my %promises = @_;

    my $all_done  = deferred();

    my $results   = {};
    my $remaining = scalar keys %promises;

    my $are_we_there_yet = sub {
        return if --$remaining;

        return if $all_done->is_rejected;

        $all_done->resolve($results);
    };

    while( my( $key, $promise ) = each %promises ) {
        unless( ref $promise eq 'Promises::Promise' or ref $promise eq 'Promises::Deferred' ) {
            my $p = deferred();
            $p->resolve($promise);
            $promise = $p;
        }

        $promise->then(sub{ $results->{$key} = shift })
            ->then( $are_we_there_yet, sub { $all_done->reject(@_) } );
    }

    return $all_done->promise;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin::FileToPackageName - turns a path into a package name

=head1 VERSION

version 1.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
