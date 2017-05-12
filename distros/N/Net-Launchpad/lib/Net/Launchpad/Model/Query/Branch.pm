package Net::Launchpad::Model::Query::Branch;
BEGIN {
  $Net::Launchpad::Model::Query::Branch::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Model::Query::Branch::VERSION = '2.101';
# ABSTRACT: Branch query model



use Moose;
use Function::Parameters;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

has '+ns' => (is => 'ro', default => 'branches');

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Query::Branch - Branch query model

=head1 VERSION

version 2.101

=head1 SYNOPSIS

    use Net::Launchpad::Client;
    use Net::Launchpad::Query;
    my $c = Net::Launchpad::Client->new(
        consumer_key        => 'key',
        access_token        => '3243232',
        access_token_secret => '432432432'
    );

    my $query = Net::Launchpad::Query->new(lpc => $c);
    my $res = $query->branches->get_by_unique_name('~adam-stokes/+junk/cloud-installer');

    print "Name: ". $res->result->{unique_name};

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
