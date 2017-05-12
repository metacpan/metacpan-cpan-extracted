package Net::Launchpad::Model::Query::Builder;
BEGIN {
  $Net::Launchpad::Model::Query::Builder::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Model::Query::Builder::VERSION = '2.101';
# ABSTRACT: Builder query model


use Moose;
use Function::Parameters;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

has '+ns' => (is => 'ro', default => 'builders');

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Query::Builder - Builder query model

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
    my $res = $query->builders->all;

    print "Num of Available Builders: ". $res->result->{total_size};

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
