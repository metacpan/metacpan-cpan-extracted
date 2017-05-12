package Plack::I18N::Lexicon::Maketext;

use strict;
use warnings;

use Carp qw(croak);
use List::Util qw(first);
use Locale::Maketext;
use Plack::I18N::Util qw(try_load_class);
use Plack::I18N::Handle;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{i18n_class} = $params{i18n_class} || croak 'i18n_class required';
    $self->{locale_dir} = $params{locale_dir};
    $self->{default_language} = $params{default_language} || 'en';

    $self->_init_lexicon;

    return $self;
}

sub _init_lexicon {
    my $self = shift;

    my $i18n_class = $self->{i18n_class};

    if (!try_load_class($i18n_class)) {
        eval <<"EOC" or croak $@;
            package $i18n_class;
            use parent 'Locale::Maketext';
            sub _loaded {1}
            1;
EOC
    }

    my $default_i18n_class = "$i18n_class\::$self->{default_language}";
    if (!try_load_class($default_i18n_class)) {
        eval <<"EOC" or croak $@;
            package $default_i18n_class;
            use parent -norequire, '$i18n_class';
            our %Lexicon = (_AUTO => 1);
            sub _loaded {1}
            1;
EOC
    }
}

sub detect_languages {
    my $self = shift;

    my $path = $self->{locale_dir} || $INC{$self->{i18n_class}} || join '/',
      'lib', split /::/, $self->{i18n_class};

    opendir(my $dh, $path) or croak "Can't opendir $path: $!";
    my @files = grep { /\.p[om]$/ && -e "$path/$_" } sort readdir($dh);
    closedir $dh;

    my @languages = @files;
    s{\.pm$}{} for @languages;

    unshift @languages, $self->{default_language}
      unless first { $_ eq $self->{default_language} } @languages;

    return @languages;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::I18N::Lexicon::Maketext - Module

=head1 SYNOPSIS



=head1 DESCRIPTION



=head1 METHODS

=head2 C<new>

=head2 C<detect_languages>

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
