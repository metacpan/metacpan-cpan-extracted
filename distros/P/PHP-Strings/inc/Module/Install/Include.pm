#line 1 "inc/Module/Install/Include.pm - /opt/perl/5.8.2/lib/site_perl/5.8.2/Module/Install/Include.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Include.pm $ $Author: autrijus $
# $Revision: #7 $ $Change: 1375 $ $DateTime: 2003/03/18 12:29:32 $ vim: expandtab shiftwidth=4

package Module::Install::Include;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

sub include {
    my ($self, $pattern) = @_;

    foreach my $rv ( $self->admin->glob_in_inc($pattern) ) {
        $self->admin->copy_package(@$rv);
    }
    return $file;
}

sub include_deps {
    my ($self, $pkg, $perl_version) = @_;
    my $deps = $self->admin->scan_dependencies($pkg, $perl_version) or return;

    foreach my $key (sort keys %$deps) {
        $self->include($key, $deps->{$key});
    }
}

1;
