##----------------------------------------------------------------------------
## Module Generic - ~/lib/Class/Boolean.pm
## Version v0.1.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/02/27
## Modified 2022/02/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Class::Boolean;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Boolean );
    our $VERSION = 'v0.1.1';
};

1;

__END__

=encoding utf8

=head1 NAME

Class::Boolean - A Boolean Object Class

=head1 SYNOPSIS

    use Class::Boolean;
    my $bool = Class::Boolean->new;

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This package provides a versatile boolean class object for the manipulation and chaining of boolean values.

See L<Module::Generic::Boolean> for more information.

=head1 SEE ALSO

L<Class::Array>, L<Class::Scalar>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
