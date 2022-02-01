###########################################
package OAuth::Cmdline::Youtube;
###########################################
use strict;
use warnings;
use MIME::Base64;
use base qw( OAuth::Cmdline );

our $VERSION = '0.07'; # VERSION
# ABSTRACT: Youtube-specific settings for OAuth::Cmdline

###########################################
sub site {
###########################################
    return "youtube";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuth::Cmdline::Youtube - Youtube-specific settings for OAuth::Cmdline

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    my $oauth = OAuth::Cmdline::Youtube->new( );
    $oauth->access_token();

=head1 DESCRIPTION

This class overrides methods of C<OAuth::Cmdline> if Youtube's Web API 
requires it.

=head1 AUTHOR

Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Mike Schilli.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
