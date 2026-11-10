requires 'perl', '5.020000';
requires 'Exporter';
# 1.45: uniq (the List::Util in the core has it from 5.26)
requires 'List::Util', '1.45';
requires 'Text::Table';
requires 'PadWalker';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Capture::Tiny', '0.12';
    requires 'Try::Tiny';
    requires 'Test::Exception';
    requires 'File::Spec';
    requires 'File::Temp';
};

on 'develop' => sub {
    # v3.2.0: manage_changes in minil.toml (the change log is CHANGELOG.md)
    requires 'Minilla', 'v3.2.0';
    requires 'Pod::Markdown::Github';
};
