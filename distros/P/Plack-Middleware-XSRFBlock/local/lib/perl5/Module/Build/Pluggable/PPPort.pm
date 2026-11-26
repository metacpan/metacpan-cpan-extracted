package Module::Build::Pluggable::PPPort;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.04';

use parent qw/Module::Build::Pluggable::Base/;
use Class::Accessor::Lite (
    ro => [qw/version filename/],
);

sub HOOK_configure {
    my ($self) = @_;
    my $version = $self->version || '3.19';
    $self->build_requires('Devel::PPPort' => $version);
    $self->configure_requires('Devel::PPPort' => $version);
}

sub HOOK_build {
    my ($self, $builder) = @_;
    require Devel::PPPort;
    my $filename = $self->filename || 'ppport.h';
    $self->add_before_action_modifier('build', sub {
        my $self = shift;
        $self->depends_on('ppport_h');
    });
    $self->add_action('ppport_h', sub {
        my $self = shift;
        unless (-e $filename) {
            $self->log_info("Writing $filename\n");
            Devel::PPPort::WriteFile($filename);
        }
        $self->add_to_cleanup($filename);
    });
}


1;
__END__

=encoding utf8

=head1 NAME

Module::Build::Pluggable::PPPort - Generate ppport.h

=head1 SYNOPSIS

    use Module::Build::Pluggable (
        'PPPort',
    );

=head1 DESCRIPTION

Generate ppport.h automatically.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<Module::Build::Pluggable>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
