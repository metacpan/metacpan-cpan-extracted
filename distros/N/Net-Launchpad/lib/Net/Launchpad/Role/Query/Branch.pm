package Net::Launchpad::Role::Query::Branch;
BEGIN {
  $Net::Launchpad::Role::Query::Branch::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Query::Branch::VERSION = '2.101';
# ABSTRACT: Branch query role

use Moose::Role;
use Function::Parameters;
use Data::Dumper::Concise;

with 'Net::Launchpad::Role::Query';


method get_by_unique_name (Str $name) {
    my $params = {
        'ws.op'     => 'getByUniqueName',
        unique_name => $name
    };
    return $self->resource($params);
}


method get_by_url (Str $url) {
    my $params = {
        'ws.op' => 'getByUrl',
        url     => $url
    };
    return $self->resource($params);
}


method get_by_urls (ArrayRef $urls) {
    my $params = {
        'ws.op' => 'getByUrls',
        urls    => join(',', @{$urls})
    };
    return $self->resource($params);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Query::Branch - Branch query role

=head1 VERSION

version 2.101

=head1 METHODS

=head2 get_by_unique_name

Find a branch by its ~owner/product/name unique name.

B<Params>

=head2 get_by_url

Find a branch by URL.

Either from the external specified in Branch.url, from the URL on
http://bazaar.launchpad.net/ or the lp: URL.

B<Params>

=head2 get_by_urls

Finds branches by URL.

Either from the external specified in Branch.url, from the URL on
http://bazaar.launchpad.net/, or from the lp: URL.

B<Params>

=for :list * C<Str name>

=for :list * C<Str url>

=for :list * C<ArrayRef urls>

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
