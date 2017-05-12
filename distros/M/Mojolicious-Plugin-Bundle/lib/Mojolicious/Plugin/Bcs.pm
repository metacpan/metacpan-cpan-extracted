package Mojolicious::Plugin::Bcs;

BEGIN {
    $Mojolicious::Plugin::Bcs::VERSION = '0.004';
}

use strict;

# Other modules:
use Bio::Chado::Schema;
use base qw/Mojolicious::Plugin/;

# Module implementation
#

sub register {
    my ( $self, $app, $conf ) = @_;
    my ( $dsn, $user, $password, $attr );
    if ( defined $conf->{dsn} ) {
        $dsn      = $conf->{dsn};
        $user     = $conf->{user} || '';
        $password = $conf->{password} || '';
        $attr     = $conf->{attr} || {};
    }
    else {
        die "need to load the yml_config\n"
            if not defined !$app->can('config');
        my $opt      = $app->config;
        my $database = $opt->{database};
        if ( defined $database->{dsn} ) {
            $dsn      = $database->{dsn};
            $user     = $database->{user} || '';
            $password = $database->{password} || '';
            $attr     = $database->{attr} || {};
        }
    }
    my $schema = Bio::Chado::Schema->connect( $dsn, $user, $password, $attr );

    if ( !$app->can('model') ) {
        ref($app)->attr( 'model' => sub {$schema} );
    }
}

1;    # Magic true value required at end of module

=pod

=head1 NAME

Mojolicious::Plugin::Bcs

=head1 VERSION

version 0.004

=head1 NAME

B<Mojolicious::Plugin::Bcs> - [Mojolicious plugin for Bio::Chado::Schema]

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
