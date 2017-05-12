#
# $Id: Entities.pm,v 1.5 2007/05/04 08:02:58 hironori.yoshida Exp $
#
package Template::Stash::HTML::Entities;

use strict;
use warnings;
use version; our $VERSION = qv('1.3.1');

use HTML::Entities;
use Template::Config;

use base ($Template::Config::STASH);

sub get {
    my $self = shift;

    my $result = $self->SUPER::get(@_);
    if ( ref $result ) {
        return $result;
    }

    return HTML::Entities::encode($result);
}

1;

__END__

=head1 NAME

Template::Stash::HTML::Entities - Encode the value automatically using HTML::Entities

=head1 VERSION

This document describes Template::Stash::HTML::Entities version 1.3.1

=head1 SYNOPSIS

    use Template::Stash::HTML::Entities;

    my $tt = Template->new({
        STASH => Template::Stash::HTML::Entities->new,
        ...
    });

or

    $Template::Config::STASH = 'Template::Stash::HTML::Entities';

=head1 DESCRIPTION

Encode the demanded value automatically.
When you need raw data (For example, using it for the textarea element),
you should decode it explicitly.

=head1 SUBROUTINES/METHODS

=head2 get(@)

When the value is not a reference, it returns the encoded value.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Template::Stash::HTML::Entities requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Template::Stash>, L<HTML::Entities>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-template-stash-html-entities@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Stash-HTML-Entities>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Hironori Yoshida C<< <yoshida@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2007, Hironori Yoshida C<< <yoshida@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
