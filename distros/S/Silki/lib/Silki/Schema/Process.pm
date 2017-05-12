package Silki::Schema::Process;
{
  $Silki::Schema::Process::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Fey::Literal::Function;
use Silki::Schema;

use Fey::ORM::Table;

my $Schema = Silki::Schema->Schema();

{
    has_policy 'Silki::Schema::Policy';

    has_table( $Schema->table('Process') );
}

with 'Silki::Role::Schema::Serializes';

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a separate process


__END__
=pod

=head1 NAME

Silki::Schema::Process - Represents a separate process

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

