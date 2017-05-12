package Mojolicious::Plugin::Bcs::Oracle;

BEGIN {
    $Mojolicious::Plugin::Bcs::Oracle::VERSION = '0.004';
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
        $attr     = $conf->{attr} || { LongReadLen => 2**20 };
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
        $attr = $database->{attr} || { LongReadLen => 2**20 };
    }

    my $schema = Bio::Chado::Schema->connect( $dsn, $user, $password, $attr );
    my $source = $schema->source('Cv::Cvtermsynonym');
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

    my $fsource     = $schema->source('Sequence::Feature');
    my $fclass_name = 'Bio::Chado::Schema::' . $fsource->source_name;
    $fsource->add_column('is_deleted');
    $fclass_name->add_column('is_deleted');
    $fclass_name->register_column('is_deleted');

    $schema->source('Organism::Organism')->remove_column('comment');

    if ( !$app->can('oracle_model') ) {
        ref($app)->attr( 'oracle_model' => sub {$schema} );
    }
}

1;    # Magic true value required at end of module

=pod

=head1 NAME

Mojolicious::Plugin::Bcs::Oracle

=head1 VERSION

version 0.004

=head1 NAME

B<Mojolicious::Plugin::Bcs::Oracle> - [Mojolicious plugin for loading BCS with
oracle database]

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
