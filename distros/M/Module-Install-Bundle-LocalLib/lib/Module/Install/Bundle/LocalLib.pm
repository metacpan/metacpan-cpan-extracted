package Module::Install::Bundle::LocalLib;
use strict;
use warnings;
use base qw(Module::Install::Base);

our $VERSION = '0.00006';

sub bundle_local_lib {
    my ($self, $lib) = @_;
    $lib ||= 'extlib';

    $self->Makefile->postamble(<<EOM);
bundle_local_lib: metafile
\t\$(NOECHO) bundledeps --extlib=$lib

bundle_local_lib_fast: metafile
\t\$(NOECHO) bundledeps --notest --extlib=$lib
EOM
}

1;

__END__

=head1 NAME

Module::Install::Bundle::LocalLib - Bundle Your Prerequisites With local::lib

=head1 SYNOPSIS

    # in your Makefile.PL
    use inc::Module::Install;

    name 'MyApp';
    requires 'Catalyst'; # or whatever

    bundle_local_lib;

    WriteAll;

    # after you typed perl Makefile.PL:
    make bundle_local_lib

    # if you don't care about running tests, do this:
    make bundle_local_lib_fast

=head1 SEE ALSO

Module::Install::Bundle::Platypus

=head1 AUTHOR

Daisuke Maki - C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
