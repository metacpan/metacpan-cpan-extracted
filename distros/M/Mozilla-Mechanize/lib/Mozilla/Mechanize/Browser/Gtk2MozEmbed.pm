package Mozilla::Mechanize::Browser::Gtk2MozEmbed;

use strict;
use warnings;

use Gtk2;
use Gtk2::MozEmbed;

use Glib::Object::Subclass Gtk2::Window::;

sub INIT_INSTANCE {
    my $self = shift;

    $self->set_title('Mozilla::Mechanize');
    Gtk2::MozEmbed->set_profile_path("$ENV{HOME}/.mozilla-mechanize", 'Mozilla::Mechanize');

    my $embed = Gtk2::MozEmbed->new();
    $self->add($embed);
    $self->{embed} = $embed;
}


1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright 2005,2009 Scott Lanning <slanning@cpan.org>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
