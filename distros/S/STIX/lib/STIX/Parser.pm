package STIX::Parser;

use 5.010001;
use strict;
use warnings;
use utf8;

use Cpanel::JSON::XS;
use STIX::Common::Hashes;
use STIX::Common::Identifier;
use STIX::Util qw(file_read);
use STIX;

use Moo;

use constant DEBUG => $ENV{STIX_DEBUG} || 0;

my %OBJECTS_MAPPING = (

    'bundle' => sub { STIX::bundle(@_) },

    'external-reference' => sub { STIX::external_reference(@_) },
    'granular-marking'   => sub { STIX::granular_marking(@_) },
    'kill-chain-phase'   => sub { STIX::kill_chain_phase(@_) },
    'marking-definition' => sub { STIX::marking_definition(@_) },

    'attack-pattern'   => sub { STIX::attack_pattern(@_) },
    'campaign'         => sub { STIX::campaign(@_) },
    'course-of-action' => sub { STIX::course_of_action(@_) },
    'grouping'         => sub { STIX::grouping(@_) },
    'identity'         => sub { STIX::identity(@_) },
    'incident'         => sub { STIX::incident(@_) },
    'indicator'        => sub { STIX::indicator(@_) },
    'infrastructure'   => sub { STIX::infrastructure(@_) },
    'intrusion-set'    => sub { STIX::intrusion_set(@_) },
    'location'         => sub { STIX::location(@_) },
    'malware'          => sub { STIX::malware(@_) },
    'malware-analysis' => sub { STIX::malware_analysis(@_) },
    'note'             => sub { STIX::note(@_) },
    'observed-data'    => sub { STIX::observed_data(@_) },
    'opinion'          => sub { STIX::opinion(@_) },
    'report'           => sub { STIX::report(@_) },
    'threat-actor'     => sub { STIX::threat_actor(@_) },
    'tool'             => sub { STIX::tool(@_) },
    'vulnerability'    => sub { STIX::vulnerability(@_) },

    'relationship' => sub { STIX::relationship(@_) },
    'sighting'     => sub { STIX::sighting(@_) },

    'artifact'             => sub { STIX::artifact(@_) },
    'autonomous-system'    => sub { STIX::autonomous_system(@_) },
    'directory'            => sub { STIX::directory(@_) },
    'domain-name'          => sub { STIX::domain_name(@_) },
    'email-addr'           => sub { STIX::email_addr(@_) },
    'email-message'        => sub { STIX::email_message(@_) },
    'file'                 => sub { STIX::file(@_) },
    'ipv4-addr'            => sub { STIX::ipv4_addr(@_) },
    'ipv6-addr'            => sub { STIX::ipv6_addr(@_) },
    'mac-addr'             => sub { STIX::mac_addr(@_) },
    'mutex'                => sub { STIX::mutex(@_) },
    'network-traffic'      => sub { STIX::network_traffic(@_) },
    'process'              => sub { STIX::process(@_) },
    'software'             => sub { STIX::software(@_) },
    'url'                  => sub { STIX::url(@_) },
    'user-account'         => sub { STIX::user_account(@_) },
    'windows-registry-key' => sub { STIX::windows_registry_key(@_) },
    'x509-certificate'     => sub { STIX::x509_certificate(@_) },

);

my %EXTENSIONS_MAPPING = (
    'archive-ext'         => sub { STIX::archive_ext(@_) },
    'http-request-ext'    => sub { STIX::http_request_ext(@_) },
    'icmp-ext'            => sub { STIX::icmp_ext(@_) },
    'ntfs-ext'            => sub { STIX::ntfs_ext(@_) },
    'pdf-ext'             => sub { STIX::pdf_ext(@_) },
    'raster-image-ext'    => sub { STIX::raster_image_ext(@_) },
    'socket-ext'          => sub { STIX::socket_ext(@_) },
    'tcp-ext'             => sub { STIX::tcp_ext(@_) },
    'unix-account-ext'    => sub { STIX::unix_account_ext(@_) },
    'windows-process-ext' => sub { STIX::windows_process_ext(@_) },
    'windows-service-ext' => sub { STIX::windows_service_ext(@_) },
);

has file    => (is => 'ro');
has content => (is => 'ro');


sub parse {

    my $self = shift;

    if ($self->content || $self->file) {

        my $content = $self->content;

        if ($self->file) {
            Carp::croak sprintf('File "%s" not found', $self->file) unless (-e $self->file);
            $content = file_read($self->file);
        }

        Carp::croak q{Empty 'content'} unless $content;

        my $parsed = Cpanel::JSON::XS->new->filter_json_object(\&_filter_json_object)->decode($content);

        Carp::croak "Failed to parse the STIX file: $@" if ($@);

        return $parsed;

    }

}

sub _filter_json_object {

    my $custom_properties = {};

    foreach my $property (keys %{$_[0]}) {

        #DEBUG and say STDERR "-- PROPERTY $property";

        my $value = $_[0]->{$property};

        if (ref($value) eq 'JSON::PP::Boolean') {
            $value = !!1 if $value;
            $value = !!0 if !$value;
        }

        if ($property =~ /_ref$/) {
            $value = STIX::Common::Identifier->new($value);
        }

        if ($property =~ /_refs$/) {

            my @refs = ();

            foreach my $ref (@{$value}) {
                push @refs, STIX::Common::Identifier->new($ref);
            }

            $value = \@refs;
        }

        if ($property eq 'hashes') {
            $value = STIX::Common::Hashes->new(%{$value});
        }

        if ($property eq 'body_multipart') {

            my @multiparts = ();

            foreach my $multipart (@{$value}) {
                push @multiparts, STIX::email_mime_part_type($multipart);
            }

            $value = \@multiparts;
        }

        if ($property eq 'x509_v3_extensions') {
            $value = STIX::x509_v3_extensions_type(%{$value});
        }

        if ($property eq 'kill_chain_phases') {


            my @multiparts = ();

            foreach my $multipart (@{$value}) {
                push @multiparts, STIX::kill_chain_phase($multipart);
            }

            $value = \@multiparts;

        }

        if ($property eq 'alternate_data_streams') {

            my @streams = ();

            foreach my $stream (@{$value}) {
                push @streams, STIX::alternate_data_stream_type($stream);
            }

            $value = \@streams;

        }

        if ($property eq 'extensions') {

            my $extensions = {};

            foreach my $extension (keys %{$value}) {

                my $data = $value->{$extension};

                if (defined $EXTENSIONS_MAPPING{$extension}) {
                    $data = $EXTENSIONS_MAPPING{$extension}->(%{$value->{$extension}});
                }

                $extensions->{$extension} = $data;
            }

            $value = $extensions;

        }

        if ($property =~ /^x_/) {
            delete $_[0]->{$property};
            $custom_properties->{$property} = $value;
        }
        else {
            $_[0]->{$property} = $value;
        }

    }

    if ($_[0]->{source_name}) {
        return STIX::external_reference(@_);
    }

    if (%{$custom_properties}) {
        DEBUG and say '-- Append "custom_properties"';
        $_[0]->{custom_properties} = $custom_properties;
    }

    if (defined $_[0]->{type} && defined $OBJECTS_MAPPING{$_[0]->{type}}) {

        if ($_[0]->{type} eq 'windows-registry-key' && defined $_[0]->{values}) {

            my @values = ();

            foreach my $value (@{$_[0]->{values}}) {
                push @values, STIX::windows_registry_value_type($value);
            }

            $_[0]->{values} = \@values;

        }

        my $object = $OBJECTS_MAPPING{$_[0]->{type}}->(@_);

        DEBUG and say sprintf('-- MAPPED "type = %s" => %s (%s)', $_[0]->{type}, ref($object), $object->id);

        return $object;

    }

    return @_;

}


1;

=encoding utf-8

=head1 NAME

STIX::Parser - Parse a STIX JSON

=head1 SYNOPSIS

    use STIX::Parser;

    # Parse a local JSON file
    my $parser = STIX::Parser->new( file => './infrastructure.json');

    # Parse a JSON string
    my $parser = STIX::Parser->new( content => $json );

    my $stix = $parser->parse;

    say $stix->type;


=head1 DESCRIPTION

Parse a STIX JSON.

=head2 METHODS

=over

=item STIX::Parser->new( [ file => $path | content => $string] )

Create a new instance of L<STIX::Parser>.

=item $parser->parse

Parse the provided JSON file (or string) and return a STIX object.

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
