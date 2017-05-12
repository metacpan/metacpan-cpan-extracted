#!perl -T

use Test::More;

BEGIN {
    use_ok('Monitoring::Livestatus::Class');
}

diag("Testing Monitoring::Livestatus::Class $Monitoring::Livestatus::Class::VERSION, Perl $], $^X");

# perl -Ilib -MModule::Find  -e 'printf "q{%s},\n",$_  for  findallmod Monitoring::Livestatus::Class::Table;'

my @tables = (
    q{Monitoring::Livestatus::Class::Table::Columns},
    q{Monitoring::Livestatus::Class::Table::Commands},
    q{Monitoring::Livestatus::Class::Table::Comments},
    q{Monitoring::Livestatus::Class::Table::Contactgroups},
    q{Monitoring::Livestatus::Class::Table::Contacts},
    q{Monitoring::Livestatus::Class::Table::Downtimes},
    q{Monitoring::Livestatus::Class::Table::Hostgroups},
    q{Monitoring::Livestatus::Class::Table::Hosts},
    q{Monitoring::Livestatus::Class::Table::Log},
    q{Monitoring::Livestatus::Class::Table::Servicegroups},
    q{Monitoring::Livestatus::Class::Table::Services},
    q{Monitoring::Livestatus::Class::Table::Servicesbygroup},
    q{Monitoring::Livestatus::Class::Table::Servicesbyhostgroup},
    q{Monitoring::Livestatus::Class::Table::Status},
    q{Monitoring::Livestatus::Class::Table::Timeperiods},
);

foreach my $table ( @tables ){
    use_ok( $table );
    my $obj;
    eval { $obj = $table->new(); };
    diag $@ if ( $@ );

    isa_ok( $obj, $table);
}

done_testing( (scalar @tables * 2) + 1);