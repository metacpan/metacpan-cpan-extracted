#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package StorageDisplay::Moose::Cached;
# ABSTRACT: Moose extension for StorageDisplay

our $VERSION = '2.02'; # VERSION

use Carp;

our %orig_has;  # save original 'has' sub routines here

sub import {
    my $callpkg = caller 0;
    {
        no strict 'refs'; ## no critic
        no warnings 'redefine';
        $orig_has{$callpkg} = *{$callpkg."::has"}{CODE};
        *{$callpkg."::has"} = \&cached_has;
    }
    return;
}

sub cached_has {
    my ($attr, %args) = @_;

    my $callpkg = caller 0;
    if (exists $args{cached_hash} ) {
        my $compute = $args{compute};
        my $type = $args{cached_hash};
        croak "'compute' attribute required" if not exists  $args{compute};
        my $cache_set = '_cached_set_'.$attr;
        my $cache_has = '_cached_has_'.$attr;
        my $cache_get = '_cached_get_'.$attr;
        $args{handles}->{$cache_set} = 'set';
        $args{handles}->{$cache_has} = 'exists';
        $args{handles}->{$cache_get} = 'get';
        %args = (
            is       => 'bare',
            required => 1,
            default  => sub { return {}; },
            lazy     => 1,
            init_arg => undef, # prevent from being set by constructor
            %args,
            traits   => [ 'Hash' ],
            isa      => "HashRef[$type]",
        );
        delete $args{cached_hash};
        delete $args{compute};
        #print STDERR "My cached arg $attr\n";
        $callpkg->meta->add_method(
            $attr => sub {
                my $self = shift;
                my $name = shift;

                if ($self->$cache_has($name)) {
                    return $self->$cache_get($name);
                }
                my $elem = $compute->($self, $name, @_);
                if (defined($elem)) {
                    $self->$cache_set($name, $elem);
                }
                return $elem;

            });
    }
    $orig_has{$callpkg}->($attr, %args);
}

BEGIN {
    # Mark current package as loaded;
    my $p = __PACKAGE__;
    $p =~ s,::,/,g;
    chomp(my $cwd = `pwd`);
    $INC{$p.'.pm'} = $cwd.'/'.__FILE__;#k"current file";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Moose::Cached - Moose extension for StorageDisplay

=head1 VERSION

version 2.02

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
