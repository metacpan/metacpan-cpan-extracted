package StateML::Utils;

$VERSION = 0.000_1;

=head1 NAME

StateML::Utils - Some handy utility functions

=head1 SYNOPSIS

    use StateML::Utils qw( empty as_string );

=head1 DESCRIPTION

Some handy uti....  you get the idea.

=cut

@EXPORT_OK = qw( empty as_str );
%EXPORT_TAGS = ( all => \@EXPORT_OK );
@ISA = qw( Exporter );
use Exporter;

use strict;

=head1 FUNCTIONS

=over

=cut

=item empty

Returns TRUE if the single arg is not defined or of zero length.  "0" is
not empty.  This does not have a prototype like defined() or length() because
the precedance can't be set properly.  Tests $_ if no parameters are passed.

=cut

sub empty {
    local $_ = shift if @_;
    return ! ( defined && length );
}

=item as_str

    warn as_str "hey!", undef.

Converts the list of parameters to a string, quoting plain scalars
if need be and reporting them as undef if they are undefined.  May
handle other situations/structures in the future.

Does an implicit join( "", ... ) in scalar context.

=cut

sub as_str {
    my @out = map 
        ref $_ ? ref $_ : defined $_ ? "'$_'" : "undef",
        @_;

    return wantarray ? @out : join "", @out;
}

=back

=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2003, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, or GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
