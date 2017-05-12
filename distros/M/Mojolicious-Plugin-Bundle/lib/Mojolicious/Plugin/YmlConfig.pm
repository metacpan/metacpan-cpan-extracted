package Mojolicious::Plugin::YmlConfig;

BEGIN {
    $Mojolicious::Plugin::YmlConfig::VERSION = '0.004';
}

use strict;

# Other modules:
use YAML qw/LoadFile/;
use base qw/Mojolicious::Plugin/;

# Module implementation
#

sub register {
    my ( $self, $app, $conf ) = @_;
    my $file;
    if ( defined $conf->{file} ) {
        $file = $conf->{file};
    }
    else {
        my $file_name = $app->mode . '.yaml';
        $file = $app->home->rel_file("conf/$file_name");
    }
    die "file $file does not exist\n" if !-e $file;

    my $stash_key = $conf->{stash_key} ? $conf->{stash_key} : 'config';
    my $data_str = LoadFile($file);

    if ( !$app->can($stash_key) ) {
        $app->log->debug("got key $stash_key");
        ref($app)->attr( $stash_key => sub {$data_str} );
    }
}

1;    # Magic true value required at end of module

=pod

=head1 NAME

Mojolicious::Plugin::YmlConfig

=head1 VERSION

version 0.004

=head1 NAME

B<Mojolicious::Plugin::YmlConfig> - [Mojolicious plugin for loading yaml config file]

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
