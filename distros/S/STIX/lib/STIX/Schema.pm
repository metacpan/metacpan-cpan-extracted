package STIX::Schema;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';

use File::Basename        qw(dirname);
use File::Spec::Functions qw(catfile);
use JSON::Validator;

use Moo;

use constant DEBUG => $ENV{STIX_DEBUG} || 0;

has object => (is => 'ro');

sub schema_cache_path { catfile(dirname(__FILE__), 'cache') }

sub validator {

    my ($self) = @_;

    my $jv = JSON::Validator->new;

    DEBUG and say sprintf('-- Load validator and use %s schema', $self->object->SCHEMA);

    $jv->cache_paths([schema_cache_path]);
    $jv->schema($self->object->SCHEMA)->schema->coerce('bool,num');

    return $jv;

}

sub validate {
    my ($self) = @_;
    return $self->validator->validate($self->object);
}

1;

=encoding utf-8

=head1 NAME

STIX::Schema - JSON Schema Validator

=head1 SYNOPSIS

    use STIX::Schema;

    my $validator = STIX::Schema->new(object => $indicator)->validator;

    my @errors = $validator->validate;

    say $_ for @errors;


=head1 DESCRIPTION

Validate STIX objects using JSON Schema.

=head2 METHODS

=over

=item STIX::Schema->new(object => $object)

=item $schema->validator

Return L<JSON::Validator> object.

=item $schema->validate

Validate and return the L<JSON::Validator> errors.

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
