package Mock::Quick::Method;
use strict;
use warnings;

use Carp         ();
use Scalar::Util ();

sub new {
    my $class = shift;
    my ($sub) = @_;

    # Fixes #11
    return $sub
        if $sub
        && Scalar::Util::blessed($sub)
        && $sub->isa($class);

    Carp::croak "Constructor to $class takes a single codeblock"
        unless ref $sub eq 'CODE';
    return bless $sub, $class;
}

1;

__END__

=head1 NAME

Mock::Quick::Method - Simple method wrapper

=head1 DESCRIPTION

See L<Mock::Quick> and L<Mock::Quick::Object> for more details.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
