package Net::Launchpad::Model::Country;
BEGIN {
  $Net::Launchpad::Model::Country::AUTHORITY = 'cpan:ADAMJS';
}
# ABSTRACT: Country model
$Net::Launchpad::Model::Country::VERSION = '2.101';

use Moose;
use namespace::autoclean;
extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Country - Country model

=head1 VERSION

version 2.101

=head1 SYNOPSIS

    use Net::Launchpad::Client;
    my $c = Net::Launchpad::Client->new(
        consumer_key        => 'key',
        access_token        => '3243232',
        access_token_secret => '432432432'
    );

    my $country = $c->country('US');

    print "Name: ". $country->result->{name};

=head1 DESCRIPTION

Container for countries

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
