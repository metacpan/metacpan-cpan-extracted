package UnoTest;

use strict;
use warnings;
use Exporter; *import = \&Exporter::import;

our @EXPORT = qw(get_file get_cu get_service_manager);

use OpenOffice::UNO;
use Cwd;

our $SMGR_URL = "uno:socket,host=localhost,port=8100;urp;StarOffice.ServiceManager";

sub get_cu {
    my ($pu) = @_;

    # can't make initialization with path work on Win32
    if ($^O eq 'MSWin32' || $ENV{URE_BOOTSTRAP}) {
        return $pu->createInitialComponentContext();
    } else {
        return $pu->createInitialComponentContext(get_file('perluno'));
    }
}

sub get_file {
    my ($file) = @_;
    my ($dir) = getcwd();

    if ($^O eq 'MSWin32') {
        # getcwd returns forward slashes, which is OK in this case
        return 'file:///' . $dir . '/' . $file;
    } else {
        return 'file://'  . $dir . '/' . $file;
    }
}

sub get_service_manager {
    my $pu = new OpenOffice::UNO();

    my $cu = get_cu($pu);
    my $sm = $cu->getServiceManager();

    my $resolver = $sm->createInstanceWithContext
                       ("com.sun.star.bridge.UnoUrlResolver", $cu);

    my $smgr = $resolver->resolve($SMGR_URL);

    return ($pu, $smgr);
}

1;
