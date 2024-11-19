package STIX::Util;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter qw(import);

use Carp;
use UUID::Tiny qw(:std);

our @EXPORT = (qw[generate_uuid get_type_from_id is_sco is_sdo is_sro is_marking file_read file_write]);

sub generate_uuid {
    my ($ns, $string) = @_;
    return create_uuid_as_string(UUID_V5, $ns, $string);
}

sub get_type_from_id {

    my $id = shift;

    Carp::croak 'Malformed identifier' unless ($id =~ /--/);

    my ($type, $uuid) = split /--/, $id;
    return $type;

}

sub is_sdo {

    my $object = shift;

    return unless $object->can('STIX_OBJECT');
    return $object->STIX_OBJECT eq 'SDO';

}

sub is_sco {

    my $object = shift;

    return unless $object->can('STIX_OBJECT');
    return $object->STIX_OBJECT eq 'SCO';

}

sub is_sro {

    my $object = shift;

    return unless $object->can('STIX_OBJECT');
    return $object->STIX_OBJECT eq 'SRO';

}

sub is_marking {

    my $object = shift;

    return unless $object->can('MARKING_TYPE');
    return 1;

}

sub file_read {

    my $file = shift;

    if (ref($file) eq 'GLOB') {
        return do { local $/; <$file> };
    }

    return do {
        open(my $fh, '<', $file) or Carp::croak qq{Failed to read file: $!};
        local $/ = undef;
        <$fh>;
    };

}

sub file_write {

    my ($file, $content) = @_;

    my $fh = undef;

    if (ref($file) eq 'GLOB') {
        $fh = $file;
    }
    else {
        open($fh, '>', $file) or Carp::croak "Can't open file: $!";
    }

    $fh->autoflush(1);

    print $fh $content;
    close($fh);

}


1;

1;

=encoding utf-8

=head1 NAME

STIX::Util - Utility for STIX

=head1 SYNOPSIS

    use STIX::Util qw(is_sdo);

    if (is_sdo($indicator)) {
        say "IS STIX Domain Object"
    }


=head1 DESCRIPTION

Utility for L<STIX>.

=head2 FUNCTIONS

=over

=item file_read($file)

Read a C<$file>.

=item file_write($file, $content)

Write the C<$content> in C<$file>

=item generate_uuid($ns, $string)

Generate UUID.

=item get_type_from_id($identifier)

Return STIX object type from the identifier.

=item is_marking($object)

Check if the provided object is a Marking object type.

=item is_sco($object)

Check if the provided object is a Cyber-observable object type.

=item is_sdo($object)

Check if the provided object is a Domain object type.

=item is_sro($object)

Check if the provided object is a Relationship object type.

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
