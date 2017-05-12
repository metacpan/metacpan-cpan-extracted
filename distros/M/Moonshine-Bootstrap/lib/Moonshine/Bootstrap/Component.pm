package Moonshine::Bootstrap::Component;

use 5.006;
use strict;
use warnings;

use Moonshine::Element;
use Moonshine::Magic;
use Moonshine::Util;
use Moonshine::Component;
use Params::Validate qw(:all);
use feature qw/switch/;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

extends ("Moonshine::Component");

our $VERSION = '0.02';

BEGIN {
    my %grid = (
       map {
              $_ => 0,
              $_ . '_base'   => { default => 'col-' . $_ . '-' },
              $_ . '_offset' => 0,
              $_ . '_offset_base'  => { default => 'col-' . $_ . '-offset-' },
              $_ . '_pull'      => 0,
              $_ . '_pull_base' => { default => 'col-' . $_ . '-pull-' },
              $_ . '_push'      => 0,
              $_ . '_push_base' => { default => 'col-' . $_ . '-push-' },
            } qw/xs sm md/
    );

    my %modify_spec = (
        (
            map { $_ => 0 }
              qw/row switch lead txt switch_base class_base sizing
              sizing_base alignment alignment_base active disable
              justified justified_base container/
        ),
        (
            map { $_ => { optional => 1, type => ARRAYREF } }
              qw/before_element after_element children/
        ),
        %grid,
        (
            map { $_ . '_base' => { default => $_ } }
              qw/active lead row container/
        ),
        disable_base => { default => 'disabled' },
        txt_base     => { default => 'text-' },
    );
    has(
        modifier_spec => sub {
            return \%modify_spec;
        },
        grid_spec => sub {
            return \%grid
        }
    );
}

sub modify {
    my $self = shift;
    my ( $base, $build, $modify ) = @_;

    for (qw/class_base/) {
        if ( defined $modify->{$_} ) {
            $base->{class} = prepend_str( $modify->{ $_ }, $base->{class} );
        }
    } 

    my @grid_keys = map  { $_ }
      grep { $_ !~ m{_base$}xms } sort keys %{ $self->grid_spec };
    for ( @grid_keys, qw/switch sizing alignment txt/ ) {
        if ( my $append_class = join_class( $modify->{ $_ . '_base' }, $modify->{$_} ) ) {
            $base->{class} = prepend_str( $append_class, $base->{class} );
        }
    }

    for (qw/active justified disable row lead/) {
        if ( defined $modify->{$_} ) {
            $base->{class} = prepend_str( $modify->{ $_ . '_base' }, $base->{class} );
        }
    }

    if ( my $container = $modify->{container} ) {
        my $cb = $modify->{container_base};
        my $container_class = ( $container =~ m/^\D/ )
          ? sprintf "%s-%s", $cb, $container
          : $cb;
        $base->{class} = prepend_str( $container_class, $base->{class} );
    }

    return $base, $build, $modify;
}

1;

__END__

=head1 NAME

Moonshine::Bootstrap::Component - HTML Bootstrap Component base.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    package Moonshine::Bootstrap::Component::Glyphicon;

    use Moonshine::Magic;
    use Moonshine::Util qw/join_class prepend_str/;

    extends 'Moonshine::Bootstrap::Component';
    
    lazy_components (qw/span/);

    sub glyphicon {
        my $self = shift;
        my ( $base_args, $build_args ) = $self->validate_build(
            {
                params => $_[0] // {},
                spec => {
                    switch      => 1,
                    switch_base => { default => 'glyphicon glyphicon-' },
                    aria_hidden => { default => 'true' },
                }
            }
        );
        return $self->span($base_args);
    }

    1;

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 LNATION.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
