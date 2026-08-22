package Punk::Plugin::I18n;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.28';

use Punk ();
use File::Spec ();
use File::Raw::JSON qw(file_json_decode);

# The catalogues are found and parsed HERE, at boot, and handed to _build
# decoded. punk_i18n.h says why this half is Perl: a directory walk in XS is
# the Win32 trap, and a decode that croaks needs the filename in the message,
# which costs two lines here and a hand-rolled JMPENV there.
#
# It runs once, before the workers fork, so none of it is on a request path.
sub register {
    my ($class, $app, $opts) = @_;
    $opts ||= {};
    ref $opts eq 'HASH'
        or die "Punk::Plugin::I18n: options must be a hashref\n";

    my $dir = $opts->{dir};
    defined $dir && length $dir
        or die "Punk::Plugin::I18n: `dir` is required - it is where the "
             . "catalogues live (plugin 'I18n' => { dir => 'i18n', "
             . "default => 'en' })\n";
    -d $dir
        or die "Punk::Plugin::I18n: the catalogue directory '$dir' does not "
             . "exist - a missing directory is a deploy that shipped without "
             . "its translations, and it should fail here rather than serve "
             . "every page in the default language\n";

    opendir my $dh, $dir
        or die "Punk::Plugin::I18n: cannot read '$dir': $!\n";
    my @files = sort grep { /\.json\z/ } readdir $dh;
    closedir $dh;

    @files
        or die "Punk::Plugin::I18n: no *.json catalogues in '$dir' - a plugin "
             . "with nothing to translate is a typo in `dir`, not a working "
             . "default\n";

    my %cats;
    for my $f (@files) {
        (my $tag = $f) =~ s/\.json\z//;
        my $path = File::Spec->catfile($dir, $f);

        open my $fh, '<:raw', $path
            or die "Punk::Plugin::I18n: cannot read '$path': $!\n";
        my $json = do { local $/; <$fh> };
        close $fh;

        # The filename, always. "malformed JSON at offset 412" names neither
        # the file nor the locale, and an application has one per language.
        my $data = eval { file_json_decode($json) };
        if ($@) {
            my $why = $@;
            $why =~ s/\s+\z//;
            die "Punk::Plugin::I18n: '$path' will not parse: $why\n";
        }
        ref $data eq 'HASH'
            or die "Punk::Plugin::I18n: '$path' is not a JSON object - a "
                 . "catalogue is a map of key to translation\n";
        $cats{$tag} = $data;
    }

    return $class->_build($app, \%cats, $opts);
}

1;

__END__

=head1 NAME

Punk::Plugin::I18n - translations and language negotiation

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'I18n' => { dir => 'i18n', default => 'en' };

    get '/' => sub {
        my ($c) = @_;
        $c->text($c->locale('greeting', name => 'Bob'));
    };

    1;

=head1 DESCRIPTION

One JSON catalogue per locale, negotiated against the request, looked up by
key.

    i18n/en.json     { "greeting": "Hello, {name}" }
    i18n/en-GB.json  { "greeting": "Hello, {name}" }
    i18n/fr.json     { "greeting": "Bonjour, {name}" }

Placeholders are C<{name}> rather than C<%s>, because positional formats
cannot be reordered and reordering is the whole reason a sentence needs
translating.

=head2 Options

=over 4

=item C<dir>

Where the catalogues live. Required.

=item C<default>

The locale used when negotiation finds nothing. Required, and it must have a
catalogue: it is the answer to every question the other sources could not
answer, so an application without one renders empty pages.

=item C<param>

The query parameter naming a locale explicitly. Defaults to C<lang>.

=item C<cookie>

Where an explicit choice is remembered. Defaults to C<punk.lang>.

=back

=head2 Catalogues are read at boot

Every catalogue is read and parsed once, before the workers fork, and is
shared across the pool for the life of the process. Nothing is read or parsed
during a request.

A catalogue that will not parse, a missing directory, or a C<default> with no
catalogue is an error at boot, in front of whoever deployed it, rather than a
missing string at three in the morning.

There is no reload. Changing a translation is a deploy.

=head2 In templates

The negotiated catalogue is on the render data as C<locale>, so a template
reads it as an ordinary dotted path with nothing passed by the handler:

    <h1>{% locale.welcome %}</h1>
    <p>{% locale.items.one %}</p>

A path is B<escaped>, which is the safe default and needs no thought. A
catalogue entry that carries markup - a link inside a sentence - needs C<raw>:

    <p>{% raw locale.tos_link %}</p>

That is safe here for a specific reason: this path takes B<no substitutions>.
The rule below is about substituted values reaching markup, and a hash has
nowhere to put one. Anything with a value in it belongs in the handler, where
C<< $c->locale($key, %values) >> escapes what it interpolates.

A missing key renders as the B<key> here too, exactly as it does through
C<< $c->locale >>: an omission cannot be visible in your code and invisible on
the page.

This needs L<Template::Stencil> 0.10 or newer.

=head2 Plurals

Pass C<count> and the category is chosen by the locale's own rule:

    "items": {
        "one":   "{count} produkt",
        "few":   "{count} produkty",
        "many":  "{count} produktow",
        "other": "{count} produktu"
    }

    $c->locale('items', count => 5);   # 5 produktow

The categories are CLDR's - C<zero>, C<one>, C<two>, C<few>, C<many> and
C<other> - and which of them a language uses, at which numbers, is the
language's business rather than yours. Polish changes form at 2 and again at
22; Arabic has a form for zero and one for two; Japanese has one form for
every number; French says "0 article". A system that branches on
C<< $count == 1 >> is English's grammar under another name, and it is wrong
B<invisibly>, because the sentence it produces is grammatical - just not for
that number.

C<other> is the category every rule can reach, so a catalogue that uses
plurals must carry it. A category the translator has not written yet falls
back to it: a partly written plural map is a translation in progress, not an
error.

B<A language whose rule is not known is a boot error> when its catalogue uses
plural categories - it is never quietly given English's rule. Ordinary strings
in such a language are unaffected.

The count is read as it was written: C<1> is C<one> in English and C<"1.0">
is C<other>, because "1.0 item" is wrong. That is CLDR's C<v> operand, and it
is the only operand that matters for whole numbers.

In a template, pluralise in the handler and pass the string in - the template
side takes no substitutions, and C<{count}> is one.

=head2 Nested keys

An object nests, and the levels join with a dot:

    { "items": { "one": "1 item", "other": "{count} items" } }

    $c->locale('items.one')

=head2 C<< $c->locale >>

    $c->locale                    # the negotiated tag, e.g. 'en-GB'
    $c->locale($key)              # the translation
    $c->locale($key, %values)     # interpolated

A key missing from the negotiated catalogue falls back to the default
catalogue, which is what a partly translated site is.

A key missing from both B<returns the key>. Not the empty string: an empty gap
hides the omission until a user finds it, while the key is visible in the page
and greppable in the logs.

The no-argument form is C<< $c->locale >> rather than a separate
C<< $c->language >>, deliberately: one name means one concept - the language
this request is in - whether you are asking which it is or asking it for a
string. The template side of it is spelled the same way.

=head2 What it counts

    my %s = Punk::Plugin::I18n->stats;   # missing, untranslated, warned

C<missing> and C<untranslated> are separate because they are different
problems. A key in no catalogue at all is a bug. A key the negotiated locale
has not translated yet, which fell back to the default, is not a bug - it is
what a partly translated site is, and the number is how an application
measures its own coverage.

A missing key also B<warns once per key, in development only>. Once, because
twenty renders of the same page producing twenty identical lines is noise, and
noise is filtered out. Development only, because a missing key in production is
already visible in the page: a line per request would be telling somebody
something they can see and cannot act on at that moment. C<warned> counts the
warnings, so "it did not warn in production" is a number rather than the
absence of one.

An unknown placeholder is left alone, so C<{nmae}> renders as C<{nmae}> rather
than vanishing. A missing value renders as nothing. A substituted value is
never rescanned for placeholders, so a user named C<{admin}> cannot reach into
the catalogue.

=head2 How a language is chosen

Explicit beats implicit:

=over 4

=item 1.

C<?lang=> - an explicit act by the user, on this request.

=item 2.

The stored choice, from the cookie - an explicit act on an earlier one.

=item 3.

C<Accept-Language> - what the browser was configured with, which is often not
what the user wants and is never something they did on this site.

=item 4.

C<default>.

=back

An explicit C<?lang=> is remembered, or a language switcher works once and
appears broken on the next link. A C<?lang=> naming a locale with no catalogue
falls through to the next source rather than failing: it is exactly the
parameter people hand-edit.

=head3 Negotiation

C<Accept-Language> is negotiated with q-values, and the two things naive
matching gets wrong:

C<en-GB> falls back to a catalogue holding C<en>, on subtag boundaries - so
C<en> never matches C<ens>. The fallback does not run the other way: a request
for C<en> is not served C<en-GB>, because serving C<pt-BR> to a request for
C<pt> gives a Portuguese speaker Brazilian spelling with no way to refuse.

C<q=0> is an exclusion rather than an absence. C<< Accept-Language: en, fr;q=0 >>
means never French, including through C<*>.

=head1 SECURITY

B<A translated string is a template, and a template is an injection site.>

The rule is: B<the catalogue is trusted, the substitutions are not.> Values
passed to C<< $c->locale >> are interpolated into a string that may contain
markup - a link inside a sentence is the ordinary case - so the catalogue is
what is allowed to carry that markup and a substituted value is not.

The consequence is worth stating plainly: B<translation files are code.> They
are reviewed as code, deployed as code, and must not be writable by anything a
user can reach. "Let the translators edit them in the admin" is a natural next
request, and it converts a trusted input into an untrusted one.

=head1 SEE ALSO

L<Punk>, L<Punk::Plugin::CSP>

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by LNATION.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
