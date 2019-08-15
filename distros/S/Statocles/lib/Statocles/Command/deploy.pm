package Statocles::Command::deploy;
our $VERSION = '0.094';
# ABSTRACT: Deploy the site

use Statocles::Base 'Command';
use Statocles::Command::build;

has build_dir => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    default => sub { Path->coercion->( '.statocles/build' ) },
);

sub run {
    my ( $self, @argv ) = @_;
    my %deploy_opt;
    GetOptionsFromArray( \@argv, \%deploy_opt,
        'date|d=s',
        'clean',
        'message|m=s',
    );

    my $deploy = $self->site->deploy;
    $deploy->site( $self->site );

    my $build_cmd = Statocles::Command::build->new( site => $self->site );
    my %build_opt;
    if ( $deploy_opt{date} ) {
        $build_opt{ '--date' } = $deploy_opt{ date };
    }
    if ( $deploy->base_url ) {
        $build_opt{ '--base_url' } = $deploy->base_url;
    }
    $build_cmd->run( $self->build_dir, %build_opt );

    $deploy->deploy( $self->build_dir, %deploy_opt );

    $self->_write_status( {
        last_deploy_date => time(),
        last_deploy_args => \%deploy_opt,
    } );

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Command::deploy - Deploy the site

=head1 VERSION

version 0.094

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
