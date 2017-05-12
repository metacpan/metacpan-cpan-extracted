package CGI::Kwiki::Cookie;
$VERSION = '0.16';
use strict;
use base 'CGI::Kwiki';
use CGI::Kwiki;

attribute 'prefs';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->prefs($self->fetch);
    return $self;
}

sub header {
    my ($self) = @_;
    my $cookie = $self->create;
    return CGI::header(
        -cookie => $cookie,
        -charset => $self->config->encoding,
    );
}

sub create{
    my ($self) = @_;
    return CGI::cookie(
        -name => 'prefs', 
        -value => { map $self->escape($_), %{$self->prefs} },
        -expires => '+5y',
        -pragma => 'no-cache',
        -cache_control => 'no-cache',
        -last_modified => gmtime,
    );
}

sub fetch {
    my ($self) = @_;
    return { map $self->unescape($_), CGI::cookie('prefs') };
}

1;

__END__

=head1 NAME 

CGI::Kwiki::CGI - CGI Base Class for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
