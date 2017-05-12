#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Minify;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Minify - Minifier base class for the Nile framework.

=head1 SYNOPSIS

    $app->plugin->minify->css($output_file => $file1, $file2, $url1, $url2, ...);
    $app->plugin->minify->js($output_file => $file1, $file2, $url1, $url2, ...);
    $app->plugin->minify->html($output_file => $file1, $file2, $url1, $url2, ...);
    $app->plugin->minify->perl($output_file => $file1, $file2, $url1, $url2, ...);

=head1 DESCRIPTION
    
Nile::Plugin::Minify - Minifier base class for the Nile framework.

See sub modules for details

L<Nile::Plugin::Minify::Css>

L<Nile::Plugin::Minify::Js>

L<Nile::Plugin::Minify::Html>

L<Nile::Plugin::Minify::Perl>

=cut

use Nile::Plugin;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
    
    my ($self) = shift;

    my ($class, $plugin) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;
    
	return $self->{$plugin}->process(@_) if ($self->{$plugin});

    my $name = "Nile::Plugin::Minify::" . ucfirst($plugin);
    
	eval "use $name";
    
    if ($@) {
        $self->app->abort("Plugin Error: $name. $@");
    }

    $self->{$plugin} = $self->app->object($name, @_);

    return $self->{$plugin}->process(@_);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
