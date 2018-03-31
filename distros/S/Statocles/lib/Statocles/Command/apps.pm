package Statocles::Command::apps;
our $VERSION = '0.092';
# ABSTRACT: List the apps in the site

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my $apps = $self->site->apps;
    for my $app_name ( keys %{ $apps } ) {
        my $app = $apps->{$app_name};
        my $root = $app->url_root;
        my $class = ref $app;
        say "$app_name ($root -- $class)";
    }
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Command::apps - List the apps in the site

=head1 VERSION

version 0.092

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
