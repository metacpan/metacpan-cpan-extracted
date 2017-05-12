package Module::Build::Pluggable::CheckLib;
use strict;
use warnings;
use utf8;
use 5.008005;
our $VERSION = '1.03';
use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_configure {
    my $self = shift;
    unless ($self->builder->have_c_compiler()) {
        warn "This distribution requires a C compiler, but it's not available, stopped.(OS unsupported)\n";
        exit 0;
    }

    $self->configure_requires('Devel::CheckLib' => '0.04');
    $self->build_requires('Devel::CheckLib' => '0.04');

    require Devel::CheckLib;

    my %opts;
    for my $key (qw/lib header incpath libpath header function/) {
        if (exists $self->{$key}) {
            $opts{$key} = $self->{$key};
        }
    }
    Devel::CheckLib::check_lib_or_exit(%opts);
}

1;
__END__

=head1 SYNOPSIS

    use Module::Build::Pluggable (
        'CheckLib' => {
            lib => 'crypto',
        },
    );

=head1 DESCRIPTION

This is a wrapper module for Devel::CheckLib.

=head1 HOW CAN I CHECK MULTIPLE LIBS?

You can use this plugin multiple times.

i.e.

    use Module::Build::Pluggable (
        'CheckLib' => {
            lib => 'crypto',
        },
        'CheckLib' => {
            lib => 'mecab',
        },
    );

