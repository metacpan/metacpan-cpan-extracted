package Template::Plugin::HTMLMobileJp;
use strict;
use warnings;
use base 'Template::Plugin';
our $VERSION = '0.02';
use HTML::MobileJp ();

for my $method (@HTML::MobileJp::EXPORT) {
    no strict 'refs';
    *{__PACKAGE__ . "::$method"} = sub {
        my ($self, $option) = @_;
        *{"HTML::MobileJp::$method"}->(%$option);
    };
}

1;
__END__

=head1 NAME

Template::Plugin::HTMLMobileJp - HTML::MobileJp plugin for Template-Toolkit

=head1 SYNOPSIS

    [% USE HTMLMobileJp %]
    [% HTMLMobileJp.gps_a({carrier => 'E', is_gps => 0, callback_url => 'http://example.com/'}) %]

=head1 DESCRIPTION

Template::Plugin::HTMLMobileJp is a wrapper of HTML::MobileJp.

You can call all method of HTML::MobileJp.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Template>, L<HTML::MobileJp>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
