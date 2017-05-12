package MooseX::AutoImmute;
use strict;
use warnings;
use Hook::AfterRuntime;

our $VERSION = '0.001';

sub import {
    my $class = shift;
    my ($moose) = @_;
    $moose ||= 'Moose';
    my $caller = caller;
    eval "package $caller; use $moose; 1" || die $@;
    after_runtime { $caller->meta->make_immutable }
}

1;

=head1 NAME

MooseX::AutoImmute - Use Moose with make_immutable called for you.

=head1 DESCRIPTION

Moose classes are littered with __PACKAGE__->meta->make_immutable(); at the
end. This is much like all packages ending with a true value. L<true> removes
the boilerplate for packages, this removes the boilerplate for L<Moose>.

=head1 SYNOPSYS

    package MyPackage;
    use strict;
    use warnings;
    use MooseX::AutoImmute;

    has ...;

    ...;

    #EOF
    # immutable autamatically!

=head1 ALTERNATIVE MOOSE

    package MyPackage;
    use strict;
    use warnings;

    # This will import Custom::Moose instead of Moose.
    use MooseX::AutoImmute qw/Custom::Moose/;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

MooseX-AutoImmute is free software; Standard perl licence.

MooseX-AutoImmute is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
