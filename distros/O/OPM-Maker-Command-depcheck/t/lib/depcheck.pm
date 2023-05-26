package   # internal package
    t::lib::depcheck;

$INC{'Kernel/System/ObjectManager.pm'} = __FILE__;

use File::Basename;
use File::Temp qw(tempfile);

our $home = dirname __FILE__;

my @files;

sub build_sopm {
    my @packages = @_;

    my $dependencies = '';

    for my $dep ( @packages ) {
        my $tag = $dep->{type} eq 'cpan' ? 'ModuleRequired' : 'PackageRequired';
        $dependencies .= sprintf qq~    <%s Version="%s">%s</%s>\n~,
            $tag, $dep->{version}, $dep->{name}, $tag;
    }

    my $sopm = sprintf q~<?xml version="1.0" encoding="utf-8" ?>
<otrs_package version="1.0">
%s
</otrs_package>
    ~, $dependencies;

    my ($fh, $filename) = tempfile( UNLINK => 0, SUFFIX => '.sopm' );
    print $fh $sopm;
    push @files, $filename;

    return $filename;
}

sub teardown {
    unlink @files;
}

package   # internal package
    t::lib::db;

my %installed = (
    FAQ             => [ 1, '6.0.1' ],
    TicketChecklist => [ 2, '6.4.1' ],
);

my @package_installation;

sub new {
    return bless {}, shift;
}

sub Prepare {
    my ($self, %args) = @_;

    my $package = ${ $args{Bind}->[0] };
    @package_installation = @{ $installed{$package} || [] };

    return 1;
}

sub FetchrowArray {
    my @row = @package_installation;
    @package_installation = ();
    return @row;
}

package   # internal package
    Kernel::System::ObjectManager;

sub new {
    return bless {}, shift;
}

sub Get {
    return t::lib::db->new;
}

1;
