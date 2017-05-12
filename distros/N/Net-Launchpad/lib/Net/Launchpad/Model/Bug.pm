package Net::Launchpad::Model::Bug;
BEGIN {
  $Net::Launchpad::Model::Bug::AUTHORITY = 'cpan:ADAMJS';
}
# ABSTRACT: Bug Model
$Net::Launchpad::Model::Bug::VERSION = '2.101';

use Moose;
use namespace::autoclean;

extends 'Net::Launchpad::Model::Base';

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Model::Bug - Bug Model

=head1 VERSION

version 2.101

=head1 SYNOPSIS

    use Net::Launchpad::Client;
    my $c = Net::Launchpad::Client->new(
        consumer_key        => 'key',
        access_token        => '3243232',
        access_token_secret => '432432432'
    );

    my $bug = $c->bug(3)

    print "Title: ". $bug->result->{title};
    print "Desc:  ". $bug->result->{description};
    print "Heat:  ". $bug->result->{heat};

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
