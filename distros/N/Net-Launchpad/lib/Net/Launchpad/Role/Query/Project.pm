package Net::Launchpad::Role::Query::Project;
BEGIN {
  $Net::Launchpad::Role::Query::Project::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Role::Query::Project::VERSION = '2.101';
# ABSTRACT: Project query role

use Moose::Role;
use Function::Parameters;
use Data::Dumper::Concise;

with 'Net::Launchpad::Role::Query';


method search (Str $text) {
    my $params = {
        'ws.op' => 'search',
        text    => $text
    };
    return $self->resource($params);
}


method latest {
    my $params = {
        'ws.op' => 'latest'
    };
    return $self->resource($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Role::Query::Project - Project query role

=head1 VERSION

version 2.101

=head1 METHODS

=head2 search

Search through the Registry database for products that match the query
terms. text is a piece of text in the title / summary / description
fields of product.

B<Params>

=head2 latest

Return latest registered projects

=for :list * C<Str text>

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
