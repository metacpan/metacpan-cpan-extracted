#
# $Id: Japanese.pm,v 1.3 2007/05/04 07:58:52 hironori.yoshida Exp $
#
package Template::Provider::Unicode::Japanese;
use strict;
use warnings;
use version; our $VERSION = qv('1.2.1');

use Template::Config;
use Unicode::Japanese;

use base ($Template::Config::PROVIDER);

sub _load {
    my $self = shift;

    my ( $data, $error ) = $self->SUPER::_load(@_);

    $data->{text} = Unicode::Japanese->new( $data->{text}, 'auto' )->getu;

    return ( $data, $error );
}

1;

__END__

=head1 NAME

Template::Provider::Unicode::Japanese - Decode all templates by Unicode::Japanese

=head1 VERSION

This document describes Template::Provider::Unicode::Japanese version 1.2.1

=head1 SYNOPSIS

    use Template::Provider::Unicode::Japanese;

    my $tt = Template->new({
        LOAD_TEMPLATES => [ Template::Provider::Unicode::Japanese->new ],
        ...
    });

or

    $Template::Config::PROVIDER = 'Template::Provider::Unicode::Japanese';

=head1 DESCRIPTION

If the utf8 flag is different between the template and
the string inserted(such as [% var %]), the output will be unreadable.
We should make all of them utf8 flagged.
However, Template::Provider::_decode_unicode decode only data with BOM.
This provider makes all templates utf8 flagged by Unicode::Japanese.

=head1 SUBROUTINES/METHODS

=head2 _load(@)

It decode the template to utf8.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Template::Provider::Unicode::Japanese requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Template::Provider>, L<Unicode::Japanese>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

=over

=item ASCII template can not have utf8 flag.

=back

Please report any bugs or feature requests to
C<bug-template-provider-unicode-japanese@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Provider-Unicode-Japanese>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Hironori Yoshida C<< <yoshida@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2007, Hironori Yoshida C<< <yoshida@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
