package RxPerl;
use 5.008001;
use strict;
use warnings FATAL => 'all';

use RxPerl::Operators::Creation ':all';
use RxPerl::Operators::Pipeable ':all';

use Exporter 'import';
our @EXPORT_OK = (
    @RxPerl::Operators::Creation::EXPORT_OK,
    @RxPerl::Operators::Pipeable::EXPORT_OK,
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = "v0.14.0";

1;
__END__

=encoding utf-8

=head1 NAME

RxPerl - It's new $module

=head1 SYNOPSIS

    use RxPerl;

=head1 DESCRIPTION

RxPerl is ...

=head1 LICENSE

Copyright (C) Alexander Karelas.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Alexander Karelas E<lt>karjala@cpan.orgE<gt>

=cut

