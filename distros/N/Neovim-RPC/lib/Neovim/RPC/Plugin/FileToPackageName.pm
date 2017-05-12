package Neovim::RPC::Plugin::FileToPackageName;
our $AUTHORITY = 'cpan:YANICK';
$Neovim::RPC::Plugin::FileToPackageName::VERSION = '0.2.0';
use 5.20.0;

use strict;
use warnings;

use Moose;
with 'Neovim::RPC::Plugin';

sub file_to_package_name {
    shift
    =~ s#^(.*/)?lib/##r
    =~ s#^/##r
    =~ s#/#::#rg
    =~ s#\.p[ml]$##r;
}

sub BUILD {
    my $self = shift;

    $self->subscribe( 'file_to_package_name', sub {
        my $msg = shift;

        my $y = 
        $self->api->vim_call_function( fname => 'expand', args => [ '%:p' ] )
        ->then( sub {
            $self->api->vim_set_current_line( line => 'package ' . file_to_package_name(shift) . ';' ) 
        });

        $y->on_done(sub{
            my $z = $y; # to get around the silly 'weaken' bug
            $z = "foo";
            $msg->done;
        });

    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin::FileToPackageName

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
