use strict;
use PerlBean;
use PerlBean::Attribute::Factory;

my $bean = PerlBean->new( {
    package => 'MyPackage',
} );
my $factory = PerlBean::Attribute::Factory->new();
my $attr = $factory->create_attribute( {
    method_factory_name => 'true',
    short_description => 'something is true',
} );
$bean->add_method_factory($attr);

use IO::File;
-d 'tmp' || mkdir('tmp');
my $fh = IO::File->new('> tmp/PerlBean.pl.out');
$bean->write($fh);
1;
