#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Minify::Js;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Minify::Js - Javascript minifier plugin for the Nile framework.

=head1 SYNOPSIS
        
=head1 DESCRIPTION

Nile::Plugin::Minify::Js - Javascript minifier plugin for the Nile framework.
    
    $app->plugin->minify->js($output_file => $file1, $file2, $url1, $url2, ...);

    $app->plugin->minify->js('site.js' => '/js/menu.js', '/js/news.js');
    
    my $path = $app->var->get("js_dir");

    $app->plugin->minify->js(
         $app->file->catfile($path, "app.js") => 
         $app->file->catfile($path, "jquery.tweet.js"),
         $app->file->catfile($path, "jquery.loading.js"),
         $app->file->catfile($path, "jquery.likes.js"),
         "http://domain.com/js/menu/menu.js",
         );

=cut

use Nile::Base;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
has 'xsmod' => (
    is      => 'rw',
    default => sub {
            if (!eval "use JavaScript::Minifier::XS;1;") {
                eval "use JavaScript::Minifier;1;";
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
        return JavaScript::Minifier::XS::minify(input => $content) || $self->app->abort("JavaScript::Minifier::XS Error");
    }
    else {
        return JavaScript::Minifier::minify(input => $content) || $self->app->abort("JavaScript::Minifier Error");
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
