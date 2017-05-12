package Test::Chado::Schema::Loader;
{
  $Test::Chado::Schema::Loader::VERSION = 'v4.1.1';
}

use base qw/DBIx::Class::Schema::Loader/;

__PACKAGE__->naming('current');
__PACKAGE__->loader_options(
    rel_name_map => {
        'cvtermsynonym_cvterms' => 'cvtermsynonyms',
        'cvtermprop_cvterms'    => 'cvtermprops',
        'phylotree_2' => 'phylotree_more'
    }
);

1;

__END__

=pod

=head1 NAME

Test::Chado::Schema::Loader

=head1 VERSION

version v4.1.1

=head1 DESCRIPTION

Its a subclass of L<DBIx::Class::Schema::Loader> primarilly to use with B<Sqlite> DBManager.

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
