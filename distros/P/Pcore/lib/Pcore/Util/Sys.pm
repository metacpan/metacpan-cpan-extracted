package Pcore::Util::Sys;

use Pcore;

sub cpus_num {
    state $cpus_num = do {
        require Sys::CpuAffinity;

        Sys::CpuAffinity::getNumCpus();
    };

    return $cpus_num;
}

1;
__END__
=pod

=encoding utf8

=cut
