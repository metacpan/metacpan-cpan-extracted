use strict;
package ObjStore::Lib::PDL::MakeMaker;
use base 'Exporter';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(os_pdl_args);

sub os_pdl_args {
    require Config;

    my $sitearch = $Config::Config{sitearch};
    $sitearch =~ s,$Config::Config{prefix},$ENV{PERL5PREFIX}, if
	exists $ENV{PERL5PREFIX};

    my %arg = @_;
    $arg{INC} .= " -I$sitearch/ObjStore/Lib/PDL";
    $arg{LIBS} ||= [''];
    for (@{$arg{LIBS}}) {
	$_ .= " -L$sitearch/auto/ObjStore/Lib/PDL -lPDL"
    }
    %arg;
}

1;
