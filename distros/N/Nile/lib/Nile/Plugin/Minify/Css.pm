#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Minify::Css;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Minify::Css - css minifier plugin for the Nile framework.

=head1 SYNOPSIS
        
=head1 DESCRIPTION

Nile::Plugin::Minify::Css - css minifier plugin for the Nile framework.
    
    $app->plugin->minify->css($output_file => $file1, $file2, $url1, $url2, ...);

    $app->plugin->minify->css('site.css' => '/css/menu.css', '/css/news.css');
    
    my $path = $app->var->get("css_dir");

    $app->plugin->minify->css(
         $app->file->catfile($path, "app.css") => 
         $app->file->catfile($path, "jquery.tweet.css"),
         $app->file->catfile($path, "jquery.loading.css"),
         $app->file->catfile($path, "jquery.likes.css"),
         "http://domain.com/js/menu/menu.css",
         );

=cut

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'xsmod' => (
    is      => 'rw',
    default => sub {
            if (!eval "use CSS::Minifier::XS;1;") {
                eval "use CSS::Minifier;1;";
                return 0;
            }
            return 1;
        },
  );
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process {

    my ($self, $out, @files) = @_;

    my $content = "";

    foreach my $file (@files) {
        $content .= $self->process_file($file);
    }

    $self->app->file->put($out, $content);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub process_file {
    
    my ($self, $file) = @_;
    
    my $content = $self->app->file->get($file);

    if ($self->xsmod) {
        return CSS::Minifier::XS::minify(input => $content) || $self->app->abort("CSS::Minifier::XS Error");
    }
    else {
        return CSS::Minifier::minify(input => $content) || $self->app->abort("CSS::Minifier Error");
    }
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
