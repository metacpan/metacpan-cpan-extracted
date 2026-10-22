package Punk::Model::Markdown;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.64';

1;

__END__

=head1 NAME

Punk::Model::Markdown - a Punk::Model backend over a markdown mount's pages

=head1 SYNOPSIS

    # the app
    markdown '/blog' => 'posts', sort => 'date';
    database blog => { backend => 'Punk::Model::Markdown', prefix => '/blog' };
    model;

    # the model
    package MyApp::Model::Post;
    use Punk::Model;
    database 'blog';
    table    'posts';
    field path    => { type => 'string', primary => 1 };
    field url     => { type => 'string' };
    field title   => { type => 'string' };
    field date    => { type => 'integer' };
    field updated => { type => 'integer' };
    field summary => { type => 'string' };
    field meta    => { type => 'object' };

    # anywhere
    my $latest = $c->model('Post')->search({ date => { '!=' => undef } },
                     { order_by => [ date => 'desc' ], limit => 3 })->{rows};

=head1 DESCRIPTION

The pages of the C<markdown> mount at C<prefix>, as rows: exactly what
L<Punk::Mount::Markdown/LISTING> lists (C<url>, C<path>, C<title>, C<date>,
C<updated>, C<summary>, C<meta>), read straight from the mount's page table,
so a blog's posts are a model like the rest of an application's data. Drafts
are not rows, because they are not pages. Under the mount's C<reload>, C<meta>
and the dates follow the last re-read of each page.

Searching works as on L<Punk::Model::JSONFile>: the same filters, ordering and
tokens as L<Punk::Model::DBI>, evaluated in memory.

The files are the pages, so C<create>, C<update> and C<delete> croak.

L<Punk::Model> hands every backend it builds the application, which is how
this one finds the mount; the C<database> needs only the C<prefix>. Asked
before the application has compiled, or for a prefix with no markdown mount,
it croaks as C<markdown_pages> does.

=head1 THE CONTRACT

=head2 get(%key)

The page whose key columns equal the values (usually C<< path => '/hello' >>),
copied, or C<undef>.

=head2 search(\%filter, \%opts)

A page of pages, C<< { rows, has_more_data, next } >>, as on
L<Punk::Model::DBI>.

=head2 count(\%filter)

How many pages match.

=head2 all()

C<< search({}, {}) >>.

=head2 create

=head2 update

=head2 delete

Croak: the pages are the markdown files.

=head1 METHODS

=head2 new

Called by L<Punk::Model> with the C<database> options (which must include a
C<prefix>), the table, the primary key, the columns and the application.

=head1 SEE ALSO

L<Punk::Model>, L<Punk::Mount::Markdown>, L<Punk::Model::JSONFile>.

=cut
