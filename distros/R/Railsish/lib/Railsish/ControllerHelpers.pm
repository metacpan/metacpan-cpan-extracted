package Railsish::ControllerHelpers;
our $VERSION = '0.21';

use strict;
use warnings;

use Exporter::Lite;
our @EXPORT = qw(notice_stickie);

sub notice_stickie {
    my ($text) = @_;
    my $session = $Railsish::Controller::session;
    push @{$session->{notice_stickies}}, { text => $text };
}

1;

__END__
=head1 NAME

Railsish::ControllerHelpers

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

