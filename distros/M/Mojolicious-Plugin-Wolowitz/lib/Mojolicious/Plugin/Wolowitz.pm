package Mojolicious::Plugin::Wolowitz;
BEGIN {
  $Mojolicious::Plugin::Wolowitz::VERSION = '1.0.1';
}
# ABSTRACT: Mojo I18n with Locale::Wolowitz

use Mojo::Base 'Mojolicious::Plugin';
use Locale::Wolowitz;

sub register {
    my ($self, $app, $config) = @_;

    my $w = Locale::Wolowitz->new( $app->home->rel_dir("i18n") );
    $app->helper(
        loc => sub {
            my ($app, $message, @args) = @_;
            $w->loc($message, $app->stash('language') || 'en' , @args);
        }
    );
}

1;


__END__
=pod

=head1 NAME

Mojolicious::Plugin::Wolowitz - Mojo I18n with Locale::Wolowitz

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    # Enable this plugin in the startup method.
    sub startup {
        my $self = shift;
        $self->plugin('wolowitz');
        ...
    }

=head1 DESCRIPTION

L<Locale::Wolowitz> is a i18n tool that use JSON as its lexicon
storage.  This Mojolicious plugin is an alternative choice to do i18n
in Mojolicious.  You'll need to make a directory named C<i18n> under
you app home, and then put translation files into there. See
L<Locale::Wolowitz> for the content format of JSON files.

=head1 METHODS

=head2 loc($message, @args)

Return the localized C<$message>. The target language is retrieved from app stash.

For example:

    # In controller
    $self->stash("zh-TW");

    # In view
    <%= loc("Nihao") %>

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Kang-min Liu.

This is free software, licensed under:

  The MIT (X11) License

=cut

