#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Plugin::Minify::Html;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Plugin::Minify::Html - Html minifier plugin for the Nile framework.

=head1 SYNOPSIS
        
=head1 DESCRIPTION

Nile::Plugin::Minify::Html - Html minifier plugin for the Nile framework.
    
    $app->plugin->minify->html($output_file => $file1, $file2, $url1, $url2, ...);

    $app->plugin->minify->html('home.html' => '/menu.html', '/body.html');
    
    my $path = $app->var->html("views_dir");

    $app->plugin->minify->html(
         $app->file->catfile($path, "home.html") => 
         $app->file->catfile($path, "header.html"),
         $app->file->catfile($path, "body.html"),
         $app->file->catfile($path, "footer.html"),
         "http://domain.com/ads/ads.html",
         );

=cut

use Nile::Base;
use HTML::Packer;
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
    
    my $packer = HTML::Packer->init();

    $packer->minify(\$content, 
                {
                    remove_newlines => 0,
                    remove_comments => 0,
                    do_javascript => 'best',
                    do_stylesheet => 'minify',
                    no_compress_comment => 1,
                    html5 => 0,
                }
            );
    
    return $content;
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
