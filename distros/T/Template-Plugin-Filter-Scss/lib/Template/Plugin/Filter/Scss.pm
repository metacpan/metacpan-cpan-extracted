package Template::Plugin::Filter::Scss;
use 5.008001;
use strict;
use warnings;

use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );

use CSS::Sass;

our $VERSION = "0.01";

sub init {
    my ($self) = @_;
    $self->install_filter('scss');
    return $self;
}

sub filter {
    my ($self, $text) = @_;

    my %options = ();
    if ($self->{ _CONFIG } && (ref($self->{ _CONFIG }) eq 'HASH')) {
        if ($self->{ _CONFIG }->{include_paths}) {
            $options{include_paths} = [$self->{ _CONFIG }->{include_paths}];
        }
        elsif ($self->{ _CONFIG }->{include_path}) {
            $options{include_paths} = [$self->{ _CONFIG }->{include_path}];
        }

        if ($self->{ _CONFIG }->{output_style}) {
            $options{output_style} = SASS_STYLE_NESTED     if uc($self->{ _CONFIG }->{output_style}) eq 'NESTED';
            $options{output_style} = SASS_STYLE_COMPACT    if uc($self->{ _CONFIG }->{output_style}) eq 'COMPACT';
            $options{output_style} = SASS_STYLE_EXPANDED   if uc($self->{ _CONFIG }->{output_style}) eq 'EXPANDED';
            $options{output_style} = SASS_STYLE_COMPRESSED if uc($self->{ _CONFIG }->{output_style}) eq 'COMPRESSED';
        }
    }

    my $sass = CSS::Sass->new(%options);

    my ($css, $stats) = $sass->compile($text);
    return $css;
}


1;
__END__

=encoding utf-8

=head1 NAME

Template::Plugin::Filter::Scss - CSS::Sass filter for Template Toolkit 

=head1 SYNOPSIS

    [% USE Filter.Scss include_paths => '/home/user/sass', output_style => 'compressed' %]

    [% FILTER scss %]
        @import "compass/css3";
        .col305 {
            position: relative;
            display: inline-block;
            width: 305px;
            vertical-align: top;
            height: 400px;
            @include opacity(0);

            &-header {
                font-size: 12px;
            }
        }
    [% END %]

=head1 OPTIONS 

=over

=item include_paths (or include_path)

Optional. This is an arrayref or a string that holds the list a of path(s) to search when following Sass @import directives.

=back

=over

=item output_style

Optional. This is a string, not case-sensitive.

'NESTED'

'COMPACT'

'EXPANDED'

'COMPRESSED'

The default is 'NESTED'.

=back

=head1 SEE ALSO

CSS::Sass - Compile .scss files using libsass L<http://search.cpan.org/~ocbnet/CSS-Sass/lib/CSS/Sass.pm>

=head1 LICENSE

Copyright (C) bbon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

bbon <bbon@mail.ru>

=cut
