package Template::Plugin::xkcd;
# ABSTRACT: WWW::xkcd plugin for Template::Toolkit
$Template::Plugin::xkcd::VERSION = '0.004';
use strict;
use warnings;

use parent 'Template::Plugin';
use WWW::xkcd;

sub new {
    my $class   = shift;
    my $context = shift;

    my $self = bless {
       'xkcd' => WWW::xkcd->new,
    }, $class;
}

sub comic {
    my $self = shift;
    my $num  = shift;
    my $meta = $self->{'xkcd'}->fetch_metadata( $num ? $num : () );

    # return HTML
    my $img = $meta->{'img'} || '';
    my $alt = $meta->{'alt'} || '';

    return qq{<img src="$img" alt="$alt" />};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Plugin::xkcd - WWW::xkcd plugin for Template::Toolkit

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # in your template
    [% USE xkcd %]

    <h1>xkcd comics!</h1>

    <p>Today's xkcd comic: [% xkcd.comic %]</p>

    <p>The 20th comic: [% xkcd.comic(20) %]</p>

=head1 DESCRIPTION

A L<Template> (Template::Toolkit) plugin to provide an image tag for xkcd
comics. You can pick which comic (either latest, or by number).

It uses L<WWW::xkcd>.

=head1 METHODS

=head2 new

This method is used by L<Template>.

If you want to use this plugin, simply add the following to your template:

    [% USE xkcd %]

=head2 comic

Fetches a comic.

Accept an optional argument for the number of a comic.

Returns an HTML <img> tag with the path and alternative text (alt text).

This gets the latest:

    [% xkcd.comic %]

This gets the first:

    [% xkcd.comic(1) %]

=head1 WHY

Just because. It's actually more useful than a lot of other stuff on CPAN. :)

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
