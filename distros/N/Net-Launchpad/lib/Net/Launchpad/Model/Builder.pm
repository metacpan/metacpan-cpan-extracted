package Net::Launchpad::Model::Builder;
BEGIN {
  $Net::Launchpad::Model::Builder::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Model::Builder::VERSION = '2.101';
# ABSTRACT: Builder Model


use Moose;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Builder - Builder Model

=head1 VERSION

version 2.101

=head1 SYNOPSIS

    use Net::Launchpad::Client;
    my $c = Net::Launchpad::Client->new(
        consumer_key        => 'key',
        access_token        => '3243232',
        access_token_secret => '432432432'
    );

    my $builder = $c->builder('batsu');

    print "Name: ". $builder->result->{name};

=head1 DESCRIPTION

Build-slave information and state.

Builder instance represents a single builder slave machine within the
Launchpad Auto Build System. It should specify a 'processor' on which
the machine is based and is able to build packages for; a URL, by
which the machine is accessed through an XML-RPC interface; name,
title for entity identification and browsing purposes; an LP-like
owner which has unrestricted access to the instance; the build slave
machine status representation, including the field/properties:
virtualized, builderok, status, failnotes and currentjob.

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
