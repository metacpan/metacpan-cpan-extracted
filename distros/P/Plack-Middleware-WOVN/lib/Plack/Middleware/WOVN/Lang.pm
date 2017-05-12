package Plack::Middleware::WOVN::Lang;
use strict;
use warnings;
use utf8;

#http://msdn.microsoft.com/en-us/library/hh456380.aspx
our $LANG = {
    'ar' => { name => 'ﺎﻠﻋﺮﺒﻳﺓ', code => 'ar', en => 'Arabic' },
    'bg' => { name => 'Български', code => 'bg', en => 'Bulgarian' },
    'zh-CHS' =>
        { name => '简体中文', code => 'zh-CHS', en => 'Simp Chinese' },
    'zh-CHT' =>
        { name => '繁體中文', code => 'zh-CHT', en => 'Trad Chinese' },
    'da' => { name => 'Dansk',            code => 'da', en => 'Danish' },
    'nl' => { name => 'Nederlands',       code => 'nl', en => 'Dutch' },
    'en' => { name => 'English',          code => 'en', en => 'English' },
    'fi' => { name => 'Suomi',            code => 'fi', en => 'Finnish' },
    'fr' => { name => 'Français',        code => 'fr', en => 'French' },
    'de' => { name => 'Deutsch',          code => 'de', en => 'German' },
    'el' => { name => 'Ελληνικά', code => 'el', en => 'Greek' },
    'he' => { name => 'עברית',       code => 'he', en => 'Hebrew' },
    'id' => { name => 'Bahasa Indonesia', code => 'id', en => 'Indonesian' },
    'it' => { name => 'Italiano',         code => 'it', en => 'Italian' },
    'ja' => { name => '日本語',        code => 'ja', en => 'Japanese' },
    'ko' => { name => '한국어',        code => 'ko', en => 'Korean' },
    'ms' => { name => 'Bahasa Melayu',    code => 'ms', en => 'Malay' },
    'no' => { name => 'Norsk',            code => 'no', en => 'Norwegian' },
    'pl' => { name => 'Polski',           code => 'pl', en => 'Polish' },
    'pt' => { name => 'Português',       code => 'pt', en => 'Portuguese' },
    'ru' => { name => 'Русский',   code => 'ru', en => 'Russian' },
    'es' => { name => 'Español',         code => 'es', en => 'Spanish' },
    'sv' => { name => 'Svensk',           code => 'sv', en => 'Swedish' },
    'th' => { name => 'ภาษาไทย', code => 'th', en => 'Thai' },
    'hi' => { name => 'हिन्दी',    code => 'hi', en => 'Hindi' },
    'tr' => { name => 'Türkçe', code => 'tr', en => 'Turkish' },
    'uk' =>
        { name => 'Українська', code => 'uk', en => 'Ukrainian' },
    'vi' => { name => 'Tiếng Việt', code => 'vi', en => 'Vietnamese' },
};

sub get_code {
    my ( $class, $lang_name ) = @_;
    return undef unless defined $lang_name;
    return $lang_name if $LANG->{$lang_name};

    $lang_name = lc $lang_name;

    for my $key ( keys %$LANG ) {
        if (   $lang_name eq lc $LANG->{$key}{name}
            || $lang_name eq lc $LANG->{$key}{en}
            || $lang_name eq lc $LANG->{$key}{code} )
        {
            return $LANG->{$key}{code};
        }
    }

    return undef;
}

sub get_lang {
    my ( $class, $lang ) = @_;
    my $lang_code = $class->get_code($lang);
    $lang_code ? $LANG->{$lang_code} : undef;
}

1;

__END__

=head1 NAME

Plack::Midleware::WOVN::Lang - Language code list that can be used by WOVN API.

=head1 SEE ALSO

L<Plack::Middleware::WOVN>

=cut

