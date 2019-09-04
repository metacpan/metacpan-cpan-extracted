requires 'perl', '5.010001';

requires 'attributes';
requires 'Carp';
requires 'Data::Dumper';
requires 'Exporter', '5.57';
requires 'File::Spec';
requires 'Guard', '1.023';
requires 'Import::Into', '1.002005';
requires 'Text::Balanced', '2.01';
requires 'strict';
requires 'subs';
requires 'vars';
requires 'vars::i', '1.10';
requires 'warnings';

on 'configure' => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on 'build' => sub {
    requires 'Cwd';
    requires 'Parse::Yapp';
};

on 'test' => sub {
    requires 'Config';
    requires 'IPC::Run3', '0.047';
    requires 'Test::Fatal', '0.014';
    requires 'Test::More', '0.98';
};

# vi: set ft=perl: #
