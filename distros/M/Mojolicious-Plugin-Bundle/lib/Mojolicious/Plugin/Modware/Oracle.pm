package Mojolicious::Plugin::Modware::Oracle;

BEGIN {
    $Mojolicious::Plugin::Modware::Oracle::VERSION = '0.004';
}

use strict;

# Other modules:
use Modware::DataSource::Chado;
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
        }
        $attr = $database->{attr} || { LongReadLen => 2**15 };
    }
    Modware::DataSource::Chado->connect(
        dsn      => $dsn,
        user     => $user,
        password => $password,
        attr     => $attr
    );
    my $instance   = Modware::DataSource::Chado->instance;
    my $source     = $instance->handler->source('Cv::Cvtermsynonym');
    my $class_name = 'Bio::Chado::Schema::' . $source->source_name;
    $source->remove_column('synonym');
    $source->add_column(
        'synonym_' => {
            data_type   => 'varchar',
            is_nullable => 0,
            size        => 1024
        }
    );
    $class_name->add_column(
        'synonym_' => {
            data_type   => 'varchar',
            is_nullable => 0,
            size        => 1024
        }
    );
    $class_name->register_column(
        'synonym_' => {
            data_type   => 'varchar',
            is_nullable => 0,
            size        => 1024
        }
    );

    my $fsource     = $instance->handler->source('Sequence::Feature');
    my $fclass_name = 'Bio::Chado::Schema::' . $fsource->source_name;
    $fsource->add_column('is_deleted');
    $fclass_name->add_column('is_deleted');
    $fclass_name->register_column('is_deleted');

    $instance->handler->source('Organism::Organism')
        ->remove_column('comment');

    if ( !$app->can('modware') ) {
        ref($app)->attr( 'modware' => sub {$instance} );
    }
}

1;    # Magic true value required at end of module

=pod

=head1 NAME

Mojolicious::Plugin::Modware::Oracle

=head1 VERSION

version 0.004

=head1 NAME

B<Mojolicious::Plugin::Modware::Oracle> - [Mojolicious plugin for loading modware with
oracle database]

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
