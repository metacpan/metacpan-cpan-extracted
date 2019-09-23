requires 'perl', '5.008001';
    # We only need 5.6, but Minilla's generated MBT Build.PL wants 5.8.1 -
    # see https://github.com/tokuhirom/Minilla/issues/167

requires 'Attribute::Handlers', '0.79';
requires 'attributes';
requires 'Carp';
requires 'constant';
requires 'Data::Dumper';
requires 'enum', '1.08';
requires 'Exporter', '5.57';
requires 'Guard', '1.023';
requires 'Import::Into', '1.002005';
requires 'parent';
requires 'Scalar::Util', '1.50';
requires 'Text::Balanced', '2.01';
requires 'Type::Params', '1.004004';    # for Dispatcher::TypeParams
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
    requires 'Data::PowerSet', '0.05';
    requires 'IPC::Run3', '0.047';
    requires 'lib::relative', '1.000';
    requires 'Test::Fatal', '0.014';
    requires 'Test::More', '0.98';
    requires 'Type::Tiny', '1.004004';
    requires 'Types::Standard';

    recommends 'Perl::PrereqScanner', '1.023';
};

# vi: set ft=perl: #
