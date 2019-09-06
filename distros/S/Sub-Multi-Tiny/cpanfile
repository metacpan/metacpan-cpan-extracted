requires 'perl', '5.008001';
    # We only need 5.6, but Minilla's generated MBT Build.PL wants 5.8.1 -
    # see https://github.com/tokuhirom/Minilla/issues/167

requires 'Attribute::Handlers', '0.79';
requires 'attributes';
requires 'Carp';
requires 'Data::Dumper';
requires 'Exporter', '5.57';
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

    # Build-time requirements, but listed at configure time to try to fix
    # http://www.cpantesters.org/cpan/report/447ab7f4-cfa7-11e9-a65e-fe3acca03743
    requires 'Cwd';
    requires 'File::Spec';
    requires 'Parse::Yapp';
    requires 'Parse::Yapp::Driver';
        # Since scan-perl-prereqs picks it up as a dependency
};

on 'test' => sub {
    requires 'Config';
    requires 'CPAN::Meta', '2.150008';
    requires 'IPC::Run3', '0.047';
    requires 'Test::Fatal', '0.014';
    requires 'Test::More', '0.98';

    recommends 'Perl::PrereqScanner', '1.023';
};

# vi: set ft=perl: #
