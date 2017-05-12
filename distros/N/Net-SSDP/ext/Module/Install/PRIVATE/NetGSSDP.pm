use strict;
use warnings;

package Module::Install::PRIVATE::NetGSSDP;

use base qw/Module::Install::Base/;

our $VERSION = '0.01';

use Cwd;
use Glib::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use File::Spec::Functions 'catfile';

sub gssdp {
    my ($self) = @_;

    mkdir 'build', 0777;

    my %pkgconfig;
    eval {
        %pkgconfig = ExtUtils::PkgConfig->find('gssdp-1.0');
    };

    if (my $error = $@) {
        print STDERR $@;
        return;
    }

    Glib::CodeGen->parse_maps('gssdp');
    Glib::CodeGen->write_boot(ignore => qr/^Net::SSDP$/);

    my @xs_files = <xs/*.xs>;

    my $gssdp = ExtUtils::Depends->new('Net::GSSDP', 'Glib');
    $gssdp->set_inc($pkgconfig{cflags} . ' -Ibuild' . ($Module::Install::AUTHOR ? ' -Wall -Werror' : ''));
    $gssdp->set_libs($pkgconfig{libs});
    $gssdp->add_xs(@xs_files);
    $gssdp->add_pm('lib/Net/SSDP.pm' => '$(INST_LIBDIR)/SSDP.pm');
    $gssdp->add_typemaps(catfile(cwd, 'build', 'gssdp.typemap'));
    $gssdp->install(catfile('build', 'gssdp-autogen.h'));
    $gssdp->save_config(catfile('build', 'IFiles.pm'));

    $self->makemaker_args(
        $gssdp->get_makefile_vars,
        MAN3PODS => {
            Glib::MakeHelper->do_pod_files(@xs_files),
        },
    );

    $self->postamble(
        Glib::MakeHelper->postamble_clean
      . Glib::MakeHelper->postamble_docs_full(
            DEPENDS   => $gssdp,
            XS_FILES  => \@xs_files,
            COPYRIGHT => 'Copyright (C) 2009, Florian Ragwitz'
        ),
    );

    return 1;
}

1;
