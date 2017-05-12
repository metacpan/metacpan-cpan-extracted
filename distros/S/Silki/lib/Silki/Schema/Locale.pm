package Silki::Schema::Locale;
{
  $Silki::Schema::Locale::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use DateTime::Locale;
use Silki::Schema;

use Fey::ORM::Table;

my $Schema = Silki::Schema->Schema();

{
    has_policy 'Silki::Schema::Policy';

    has_table( $Schema->table('Locale') );

    has_many countries => (
        table    => $Schema->table('Country'),
        order_by => [ $Schema->table('Country')->column('name'), 'ASC' ],
    );
}

sub CreateDefaultLocales {
    my $class = shift;

    for my $code ( DateTime::Locale->ids() ) {
        next if $class->new( locale_code => $code );

        $class->insert( locale_code => $code );
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a locale

__END__
=pod

=head1 NAME

Silki::Schema::Locale - Represents a locale

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

