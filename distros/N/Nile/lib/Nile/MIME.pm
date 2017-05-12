#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::MIME;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 MIME

Nile::MIME - Handle MIME Types

=head1 SYNOPSIS

    # get mime object instance
    $mime = $app->mime;

    # get mime type for a file from its extension
    $mime_type = $mime->for_file("filename.zip");
    # application/zip

    # get mime type by name
    $mime_type = $mime->for_name('xml');
    # application/xml

    # add custom mime type
    $mime->add_type(foo => "text/foo");

    # add an alias to an existing type
    $mime->add_alias(bar => "foo");

    @exts = $mime->extensions();

=head1 DESCRIPTION

Nile::MIME - Handle MIME Types. This module extends L<MIME::Types> and all its methods are available.

=cut

use Nile::Base;
use MooseX::NonMoose;
extends 'MIME::Types';
#=========================================================#
has 'default' => (
        is          => 'rw',
        default => 'application/data',
  );

  
has 'custom_types' => (
        is => 'rw',
        isa => 'HashRef',
        default =>  sub { +{ } }
    );

#=========================================================#
=head2 for_file

    $mime_type = $mime->for_file('filename.pdf');

Returns the mime type for a file, based on a file extension.

=cut

sub for_file {
    my ($self, $file) = @_;
    my ($ext) = $file =~ /\.([^.]+)$/;
    return $self->default unless $ext;
    return $self->for_name($ext);
}
#=========================================================#
=head2 for_name

    $mime_type = $mime->for_name('pdf');

Returns the mime type for a standard or a custom mime type.

=cut

sub for_name {
    my ($self, $name) = @_;
    return $self->custom_types->{lc $name} || $self->mimeTypeOf(lc $name) || $self->default;
}
#=========================================================#
=head2 add_type

    # add nonstandard mime type
    $mime->add_type(foo => "text/foo");

Add a custom mime type or overrides an existing one.

=cut

sub add_type {
    my ($self, $name, $type) = @_;
    $self->custom_types->{$name} = $type;
    $self;
}
#=========================================================#
=head2 add_alias

    # add alias to standard or previous alias
    $mime->add_alias( my_jpg => 'jpg' );

Adds an alias to an existing mime type.

=cut

sub add_alias {
    my ($self, $alias, $orig) = @_;
    my $type = $self->name($orig);
    $self->add_type($alias, $type);
    return $type;
}
#=========================================================#

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 ACKNOWLEDGMENT

This module is based on L<MIME::Types> and L<Dancer::MIME>

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
