package Module::Build::Pluggable::DistTestLibCoreOnly;
use strict;
use warnings;
use 5.008005;
our $VERSION = '0.0.6';

use parent qw/Module::Build::Pluggable::Base/;

sub HOOK_build {
    my $self = shift;

    $self->add_around_action_modifier(
        "disttest", \&_disttest
    );
}

sub _disttest {
    my ($code, $self) = @_;

    $self->depends_on('distdir');

    _do_in_dir(
        $self,
        $self->dist_dir,
        sub {
            # XXX could be different names for scripts

            system('cpanm', '-L', '_local_lib/', '--installdeps', '.');
            $ENV{PERL5OPT} = sprintf('-Mlib::core::only -Mlib=%s -Mlib=%s',
                File::Spec->rel2abs('_local_lib/lib/perl5'),
                File::Spec->rel2abs('lib')
            );

            $self->run_perl_script('Build.PL')    # XXX Should this be run w/ --nouse-rcfile
              or die "Error executing 'Build.PL' in dist directory: $!";

            $self->run_perl_script('Build')
              or die "Error executing 'Build' in dist directory: $!";
            $self->run_perl_script( 'Build', [], ['test'] )
              or die "Error executing 'Build test' in dist directory";
        }
    );
}

# taken from M::B::Base
sub _do_in_dir {
    my ( $self, $dir, $do ) = @_;

    my $start_dir = File::Spec->rel2abs( $self->cwd );
    chdir $dir or die "Can't chdir() to $dir: $!";
    eval { $do->() };
    my @err = $@ ? ($@) : ();
    chdir $start_dir or push @err, "Can't chdir() back to $start_dir: $!";
    die join "\n", @err if @err;
}

1;
__END__

=encoding utf8

=head1 NAME

Module::Build::Pluggable::DistTestLibCoreOnly - (EXPERIMENTAL) run disttest with local lib

=head1 SYNOPSIS

    use Module::Build::Pluggable qw(
        DistTestLibCoreOnly
    );

=head1 DESCRIPTION

Run disttest with depended modules wrote in deps only.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

This plugin installs depended modules to C< _local_lib/ > by C< cpanm -L _local_lib/ >.
And run the test cases with the libraries only.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
