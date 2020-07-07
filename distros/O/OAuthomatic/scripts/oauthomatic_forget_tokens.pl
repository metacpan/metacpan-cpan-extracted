#!/usr/bin/perl -w
# PODNAME: oauthomatic_forget_tokens
# ABSTRACT: remove remembered tokens for given site

use strict;
use warnings;


{
    package OAuthomaticForgetTokens;
    use Moose;
    our $VERSION = '0.0202'; # VERSION
    with 'MooseX::Getopt';
    has 'password_group' => (is=>'ro', isa=>'Str', required=>1);
    has 'site_name' => (is=>'ro', isa=>'Str', required=>1);
    has 'app' => (is=>'ro', isa=>'Bool', default=>'OAuthomatic');

    sub run {
        my ($self) = @_;
        die "Not yet implemented\n";
    }
}

my $app = OAuthomaticForgetTokens->new_with_options;
$app->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

oauthomatic_forget_tokens - remove remembered tokens for given site

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

Drops OAuth tokens related to given site, if any are remembered. 

Assumes default keyring is in use;

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
