use inc::Module::Install;

name('Term-Encoding');
all_from('lib/Term/Encoding.pm');

features(
    'query locale information' => [
        -default => 1,
        recommends('I18N::Langinfo'),
    ],
);

if ($^O eq 'MSWin32') {
    features(
        'query win32 console information' => [
            -default => 1,
            requires('Win32::Console'),
        ],
    );
}

auto_include;
WriteAll;
