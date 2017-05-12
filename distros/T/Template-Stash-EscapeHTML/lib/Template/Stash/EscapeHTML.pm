package Template::Stash::EscapeHTML;

use strict;
use Template::Config;
use base ($Template::Config::STASH);
our $VERSION = '0.02';

sub get {
    my($self, @args) = @_;
    my($var) = $self->SUPER::get(@args);
    unless (ref($var)) {
        return html_filter($var);
    }
    return $var;
}

sub html_filter {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
        s/'/&#39;/g;
    }
    return $text;
}

1;

__END__

=head1 NAME

Template::Stash::EscapeHTML - escape HTML automatically in Template-Toolkit.

=head1 SYNOPSIS

    use Template::Stash::EscapeHTML;
    
    my $tt = Template->new({
        STASH => Template::Stash::EscapeHTML->new,
        ...
    }); 

=head1 DESCRIPTION

This module is a sub class of L<Template::Stash>,
automatically escape all HTML strings and avoid XSS vulnerability.

=head1 AUTHOR

Tomohiro IKEBE, C<< <ikebe@shebang.jp> >>

=head1 COPYRIGHT

Copyright 2005 Tomohiro IKEBE, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
