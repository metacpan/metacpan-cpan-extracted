use warnings;
use strict;

package RT::Extension::MobileUI;

our $VERSION = "1.07";

sub _encode_surrogates {
    my $uni = $_[0] - 0x10000;
    return ($uni /  0x400 + 0xD800, $uni % 0x400 + 0xDC00);
}

sub EscapeJS {
    my $val = shift;
    return unless defined $val;

    return "'" . join('',
                 map {
                     chr($_) =~ /[a-zA-Z0-9]/ ? chr($_) :
                     $_  <= 255   ? sprintf("\\x%02X", $_) :
                     $_  <= 65535 ? sprintf("\\u%04X", $_) :
                     sprintf("\\u%X\\u%X", _encode_surrogates($_))
                 } unpack('U*', $val))
        . "'";
}

=head1 NAME

RT::Extension::MobileUI - DEPRECATED A phone friendly web interface for RT

=head1 DEPRECATED

A version of this module was integrated into RT in 4.0.0.  RT will
automatically serve a mobile-friendly web interface on 4.0.0 or greater.

=head1 DESCRIPTION

This RT extension adds a mobile interface for RT.

=head1 INSTALLATION

    # perl Makefile.PL
    # make
    # make install

    Add RT::Extension::MobileUI to your /opt/rt3/etc/RT_SiteConfig.pm file
    Set(@Plugins, qw(RT::Extension::MobileUI));

    If you have more than one Plugin enabled, you must enable them as one 
    Set(@Plugins, qw(Foo Bar)); command

    # clear mason cache
    # restart apache
=cut




sub MobileClient {
    my $self = shift;


if (($ENV{'HTTP_USER_AGENT'} || '') =~ /(?:hiptop|Blazer|Novarra|Vagabond|SonyEricsson|Symbian|NetFront|UP.Browser|UP.Link|Windows CE|MIDP|J2ME|DoCoMo|J-PHONE|PalmOS|PalmSource|iPhone|iPod|AvantGo|Nokia|Android|WebOS|S60)/io && !$HTML::Mason::Commands::session{'NotMobile'})  {
    return 1;
} else {
    return undef;
}

}

# while /m/tickets/search could be used to run a denial-of-service
# attack against RT by tricking your browser into running inefficient
# searches, it's really useful to be able to bookmark search results
# so we allow direct access to it.
$RT::Interface::Web::is_whitelisted_component{'/m/tickets/search'} = 1;


=head1 AUTHOR

Jesse Vincent E<lt>jesse@bestpractical.comE<gt>

=head1 LICENSE

GPL version 2.

=cut

1;
