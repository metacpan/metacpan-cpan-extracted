package Statocles::Command::deploy;
our $VERSION = '0.092';
# ABSTRACT: Deploy the site

use Statocles::Base 'Command';

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
    my @pages = $self->site->pages( %deploy_opt, base_url => $deploy->base_url );

    #; say "Deploying pages: " . join "\n", map { $_->path } @pages;
    $deploy->deploy( \@pages, %deploy_opt );

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

version 0.092

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
