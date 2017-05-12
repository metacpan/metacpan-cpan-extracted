package Net::Launchpad::Model::CVE;
BEGIN {
  $Net::Launchpad::Model::CVE::AUTHORITY = 'cpan:ADAMJS';
}
# ABSTRACT: CVE Model
$Net::Launchpad::Model::CVE::VERSION = '2.101';

use Moose;
use namespace::autoclean;
extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::CVE - CVE Model

=head1 VERSION

version 2.101

=head1 SYNOPSIS

    use Net::Launchpad::Client;
    my $c = Net::Launchpad::Client->new(
        consumer_key        => 'key',
        access_token        => '3243232',
        access_token_secret => '432432432'
    );

    my $cve = $c->cve('XXXX-XXXX');

    print "Title: ". $cve->result->{title};
    print "Desc:  ". $cve->result->{description};

=head1 METHODS

=head2 by_sequence

This needs to be called before any of the below methods. Takes a CVE sequence number, e.g. 2011-3188.

=head2 bugs

Returns a list of entries associated with cve

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
