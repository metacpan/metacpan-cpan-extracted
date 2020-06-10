package Mojo::Rx;
use 5.008001;
use strict;
use warnings;

use Mojo::Rx::Operators::Creation ':all';
use Mojo::Rx::Operators::Pipeable ':all';

use Exporter 'import';
our @EXPORT_OK = (
    @Mojo::Rx::Operators::Creation::EXPORT_OK,
    @Mojo::Rx::Operators::Pipeable::EXPORT_OK,
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v0.13.0";

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::Rx - It's new $module

=head1 SYNOPSIS

    use Mojo::Rx;

=head1 DESCRIPTION

Mojo::Rx is ...

=head1 LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut

